import { supabaseAdmin } from '../config/supabase';
import { Person, Relationship, TreeNode, TreeResponse, SearchResult } from '../models/types';

/**
 * GraphService: handles family tree traversal.
 *
 * Uses batch-loading to avoid N+1 query problems:
 * - Each "hop" loads all persons and relationships in 2 queries
 * - Typically finishes in 2-3 hops (6 queries) instead of 200+ sequential queries
 */

/**
 * Get the full family tree for a person.
 * Returns all connected persons (unlimited depth) with their relationships.
 */
export async function getFullTree(personId: string): Promise<TreeResponse> {
  // Try the recursive CTE RPC first (most efficient)
  const { data, error } = await supabaseAdmin.rpc('get_full_tree', {
    root_person_id: personId,
  });

  if (error) {
    // Fallback: use batch-loaded BFS if RPC not available
    return getFullTreeFallback(personId);
  }

  return { nodes: data, rootPersonId: personId };
}

/**
 * Fallback: build tree using batch-loaded BFS traversal.
 *
 * Instead of querying one person at a time (N+1 problem),
 * we batch-load all persons and relationships per hop level.
 * A typical family tree completes in 2-4 hops = 4-8 DB queries total.
 */
async function getFullTreeFallback(personId: string): Promise<TreeResponse> {
  const personMap = new Map<string, Person>();
  const relMap = new Map<string, Relationship[]>();
  let toLoad = new Set<string>([personId]);
  const allLoaded = new Set<string>();

  // Batch-load hop by hop until no new persons are discovered
  while (toLoad.size > 0) {
    const idsToLoad = Array.from(toLoad);
    idsToLoad.forEach(id => allLoaded.add(id));

    // Batch load persons for this hop
    const { data: persons, error: personError } = await supabaseAdmin
      .from('persons')
      .select('*')
      .in('id', idsToLoad);

    if (personError || !persons) break;

    for (const p of persons) {
      personMap.set(p.id, p as Person);
    }

    // Batch load all relationships for these persons
    const { data: relationships, error: relError } = await supabaseAdmin
      .from('relationships')
      .select('*')
      .in('person_id', idsToLoad);

    if (relError) break;

    // Group relationships by person_id and discover new persons
    const nextToLoad = new Set<string>();

    for (const rel of (relationships || [])) {
      const r = rel as Relationship;
      if (!relMap.has(r.person_id)) {
        relMap.set(r.person_id, []);
      }
      relMap.get(r.person_id)!.push(r);

      // Queue newly discovered persons for the next hop
      if (!allLoaded.has(r.related_person_id)) {
        nextToLoad.add(r.related_person_id);
      }
    }

    toLoad = nextToLoad;
  }

  // Build TreeNode[] from collected data
  const nodes: TreeNode[] = [];
  for (const [id, person] of personMap) {
    nodes.push({
      person,
      relationships: relMap.get(id) || [],
    });
  }

  return { nodes, rootPersonId: personId };
}

/**
 * Search for persons within N circles (hops) of a starting person.
 * Supports filtering by name, occupation, city, state, and marital status.
 *
 * Uses batch-loading: 2 queries per depth level instead of 1 per person.
 */
export async function searchInCircles(params: {
  personId: string;
  maxDepth: number;
  query?: string;
  occupation?: string;
  city?: string;
  state?: string;
  maritalStatus?: string;
}): Promise<SearchResult[]> {
  const { personId, maxDepth, query, occupation, city, state, maritalStatus } = params;

  // Track depth and connection paths for each discovered person
  const depthMap = new Map<string, number>();
  const pathMap = new Map<string, string[]>();
  const personMap = new Map<string, Person>();

  depthMap.set(personId, 0);
  pathMap.set(personId, [personId]);

  let currentIds = new Set<string>([personId]);
  const allVisited = new Set<string>([personId]);

  // BFS hop by hop with batch loading
  for (let depth = 0; depth <= maxDepth; depth++) {
    if (currentIds.size === 0) break;

    const idsToLoad = Array.from(currentIds);

    // Batch load persons for current hop level
    const { data: persons } = await supabaseAdmin
      .from('persons')
      .select('*')
      .in('id', idsToLoad);

    if (persons) {
      for (const p of persons) {
        personMap.set(p.id, p as Person);
      }
    }

    // If we haven't reached max depth, load relationships to find next hop
    if (depth < maxDepth) {
      const { data: relationships } = await supabaseAdmin
        .from('relationships')
        .select('person_id, related_person_id')
        .in('person_id', idsToLoad);

      const nextIds = new Set<string>();

      if (relationships) {
        for (const rel of relationships) {
          if (!allVisited.has(rel.related_person_id)) {
            allVisited.add(rel.related_person_id);
            nextIds.add(rel.related_person_id);
            depthMap.set(rel.related_person_id, depth + 1);
            pathMap.set(rel.related_person_id, [
              ...(pathMap.get(rel.person_id) || []),
              rel.related_person_id,
            ]);
          }
        }
      }

      currentIds = nextIds;
    } else {
      currentIds = new Set(); // No more hops
    }
  }

  // Apply filters and build results (skip root person)
  const results: SearchResult[] = [];

  for (const [id, person] of personMap) {
    const personDepth = depthMap.get(id);
    if (personDepth === undefined || personDepth === 0) continue; // Skip root

    let matches = true;

    if (query) {
      const q = query.toLowerCase();
      matches = matches && (
        person.name.toLowerCase().includes(q) ||
        (person.occupation?.toLowerCase().includes(q) ?? false) ||
        (person.city?.toLowerCase().includes(q) ?? false) ||
        (person.state?.toLowerCase().includes(q) ?? false)
      );
    }

    if (occupation) {
      matches = matches && (person.occupation?.toLowerCase().includes(occupation.toLowerCase()) ?? false);
    }

    if (city) {
      matches = matches && (person.city?.toLowerCase().includes(city.toLowerCase()) ?? false);
    }

    if (state) {
      matches = matches && (person.state?.toLowerCase().includes(state.toLowerCase()) ?? false);
    }

    if (maritalStatus) {
      matches = matches && person.marital_status === maritalStatus;
    }

    if (matches) {
      results.push({
        person,
        depth: personDepth,
        path: pathMap.get(id) || [id],
      });
    }
  }

  // Sort by depth (closest connections first)
  results.sort((a, b) => a.depth - b.depth);

  return results;
}

/**
 * Get the person record linked to a Supabase auth user.
 */
export async function getPersonByAuthUser(authUserId: string): Promise<Person | null> {
  const { data, error } = await supabaseAdmin
    .from('persons')
    .select('*')
    .eq('auth_user_id', authUserId)
    .single();

  if (error || !data) return null;
  return data as Person;
}

/**
 * Get the names for a path of person IDs (for displaying connection paths).
 */
export async function getPathNames(personIds: string[]): Promise<string[]> {
  if (personIds.length === 0) return [];

  const { data } = await supabaseAdmin
    .from('persons')
    .select('id, name')
    .in('id', personIds);

  if (!data) return [];

  const nameMap = new Map(data.map((p: any) => [p.id, p.name]));
  return personIds.map(id => nameMap.get(id) || 'Unknown');
}

/**
 * Find multiple connection paths between two persons using BFS.
 * Returns up to 3 paths, common ancestors, and relationship statistics.
 * Works across the entire graph — the two people do NOT need to be in the same tree.
 */
export async function findConnection(
  personAId: string,
  personBId: string,
  maxDepth: number = 20,
  maxPaths: number = 3
): Promise<{
  connected: boolean;
  paths: Array<{
    path: { personId: string; name: string; gender: string }[];
    relationships: { from: string; to: string; type: string; label: string }[];
    depth: number;
  }>;
  commonAncestors: Array<{ personId: string; name: string; distanceFromA: number; distanceFromB: number }>;
  statistics: {
    totalPaths: number;
    shortestDistance: number;
    longestDistance: number;
  };
  // Legacy fields for backward compatibility
  path: { personId: string; name: string; gender: string }[];
  relationships: { from: string; to: string; type: string; label: string }[];
  depth: number;
} | null> {
  if (personAId === personBId) {
    // Same person
    const { data } = await supabaseAdmin
      .from('persons')
      .select('id, name, gender')
      .eq('id', personAId)
      .single();
    if (!data) return null;
    const selfPath = {
      path: [{ personId: data.id, name: data.name, gender: data.gender }],
      relationships: [],
      depth: 0,
    };
    return {
      connected: true,
      paths: [selfPath],
      commonAncestors: [],
      statistics: { totalPaths: 1, shortestDistance: 0, longestDistance: 0 },
      ...selfPath, // Legacy fields
    };
  }

  // Multi-path BFS: Track all paths up to maxPaths
  const visitedFromA = new Map<string, number>(); // person -> distance from A
  const visitedFromB = new Map<string, number>(); // person -> distance from B
  const parentsA = new Map<string, Array<{ parentId: string; relType: string }>>(); // child -> parents
  const parentsB = new Map<string, Array<{ parentId: string; relType: string }>>(); // child -> parents
  
  visitedFromA.set(personAId, 0);
  visitedFromB.set(personBId, 0);
  
  let queueA = [personAId];
  let queueB = [personBId];
  let meetingPoints = new Set<string>();
  let minDistance = Infinity;
  
  // Bidirectional BFS
  for (let depth = 0; depth < maxDepth && queueA.length > 0 && queueB.length > 0; depth++) {
    // Expand from the smaller frontier
    const expandFromA = queueA.length <= queueB.length;
    const currentQueue = expandFromA ? queueA : queueB;
    const visited = expandFromA ? visitedFromA : visitedFromB;
    const otherVisited = expandFromA ? visitedFromB : visitedFromA;
    const parents = expandFromA ? parentsA : parentsB;
    
    if (currentQueue.length === 0) break;

    // Check if we've gone beyond the minimum distance
    if (meetingPoints.size > 0 && depth > minDistance) break;

    const { data: relsForward } = await supabaseAdmin
      .from('relationships')
      .select('person_id, related_person_id, type')
      .in('person_id', currentQueue);
    
    const { data: relsReverse } = await supabaseAdmin
      .from('relationships')
      .select('person_id, related_person_id, type')
      .in('related_person_id', currentQueue);

    const nextQueue: string[] = [];
    const allEdges: { from: string; to: string; type: string }[] = [];

    for (const rel of (relsForward || [])) {
      allEdges.push({ from: rel.person_id, to: rel.related_person_id, type: rel.type });
    }
    for (const rel of (relsReverse || [])) {
      const reverseType = flipRelationshipType(rel.type);
      allEdges.push({ from: rel.related_person_id, to: rel.person_id, type: reverseType });
    }

    for (const edge of allEdges) {
      const currentDist = visited.get(edge.from)!;
      const newDist = currentDist + 1;
      
      // Check if we've found a meeting point
      if (otherVisited.has(edge.to)) {
        const totalDist = newDist + otherVisited.get(edge.to)!;
        if (totalDist <= minDistance) {
          minDistance = totalDist;
          meetingPoints.add(edge.to);
        }
      }
      
      if (!visited.has(edge.to)) {
        visited.set(edge.to, newDist);
        nextQueue.push(edge.to);
        parents.set(edge.to, [{ parentId: edge.from, relType: edge.type }]);
      } else if (visited.get(edge.to) === newDist) {
        // Same distance - add alternate parent for multiple paths
        const existing = parents.get(edge.to) || [];
        existing.push({ parentId: edge.from, relType: edge.type });
        parents.set(edge.to, existing);
      }
    }

    if (expandFromA) {
      queueA = nextQueue;
    } else {
      queueB = nextQueue;
    }
  }

  if (meetingPoints.size === 0) {
    return {
      connected: false,
      paths: [],
      commonAncestors: [],
      statistics: { totalPaths: 0, shortestDistance: -1, longestDistance: -1 },
      path: [],
      relationships: [],
      depth: -1,
    };
  }

  // Find common ancestors (people visited from both sides)
  const commonAncestors: Array<{ personId: string; name: string; distanceFromA: number; distanceFromB: number }> = [];
  for (const [personId, distA] of visitedFromA) {
    if (visitedFromB.has(personId) && personId !== personAId && personId !== personBId) {
      const distB = visitedFromB.get(personId)!;
      commonAncestors.push({ personId, name: '', distanceFromA: distA, distanceFromB: distB });
    }
  }

  // Sort common ancestors by total distance (closest first)
  commonAncestors.sort((a, b) => (a.distanceFromA + a.distanceFromB) - (b.distanceFromA + b.distanceFromB));

  // Fetch names for common ancestors
  if (commonAncestors.length > 0) {
    const { data: ancestorPersons } = await supabaseAdmin
      .from('persons')
      .select('id, name')
      .in('id', commonAncestors.map(a => a.personId));
    const nameMap = new Map((ancestorPersons || []).map((p: any) => [p.id, p.name]));
    commonAncestors.forEach(a => a.name = nameMap.get(a.personId) || 'Unknown');
  }

  // Reconstruct multiple paths through meeting points
  const allPaths: Array<{
    path: { personId: string; name: string; gender: string }[];
    relationships: { from: string; to: string; type: string; label: string }[];
    depth: number;
  }> = [];

  const reconstructedPaths = new Set<string>(); // To avoid duplicates

  for (const meetPoint of Array.from(meetingPoints).slice(0, maxPaths * 2)) {
    const paths = reconstructPathsThroughMeetingPoint(
      meetPoint,
      personAId,
      personBId,
      parentsA,
      parentsB,
      maxPaths - allPaths.length
    );
    
    for (const p of paths) {
      const pathKey = p.map(id => id).join('-');
      if (!reconstructedPaths.has(pathKey) && allPaths.length < maxPaths) {
        reconstructedPaths.add(pathKey);
        allPaths.push(await buildPathObject(p, parentsA, parentsB, personAId, meetPoint));
      }
    }
    
    if (allPaths.length >= maxPaths) break;
  }

  // Sort by depth (shortest first)
  allPaths.sort((a, b) => a.depth - b.depth);

  const statistics = {
    totalPaths: allPaths.length,
    shortestDistance: allPaths.length > 0 ? allPaths[0].depth : -1,
    longestDistance: allPaths.length > 0 ? allPaths[allPaths.length - 1].depth : -1,
  };

  return {
    connected: true,
    paths: allPaths,
    commonAncestors: commonAncestors.slice(0, 5), // Top 5 common ancestors
    statistics,
    // Legacy fields (use first path)
    path: allPaths[0]?.path || [],
    relationships: allPaths[0]?.relationships || [],
    depth: allPaths[0]?.depth || 0,
  };
}

/**
 * Reconstruct paths from personA to personB through a meeting point
 */
function reconstructPathsThroughMeetingPoint(
  meetPoint: string,
  personAId: string,
  personBId: string,
  parentsA: Map<string, Array<{ parentId: string; relType: string }>>,
  parentsB: Map<string, Array<{ parentId: string; relType: string }>>,
  maxPaths: number
): string[][] {
  // Get all paths from A to meeting point
  const pathsFromA = reconstructAllPaths(meetPoint, personAId, parentsA, Math.ceil(maxPaths / 2));
  const pathsFromB = reconstructAllPaths(meetPoint, personBId, parentsB, Math.ceil(maxPaths / 2));

  const fullPaths: string[][] = [];
  for (const pathA of pathsFromA) {
    for (const pathB of pathsFromB) {
      if (fullPaths.length >= maxPaths) break;
      // Combine: A -> ... -> meetPoint -> ... -> B
      // Reverse pathB and remove duplicate meeting point
      const reversedB = [...pathB].reverse();
      reversedB.shift(); // Remove meeting point duplicate
      fullPaths.push([...pathA, ...reversedB]);
    }
    if (fullPaths.length >= maxPaths) break;
  }

  return fullPaths;
}

/**
 * Reconstruct all paths from target back to source using parent map (DFS)
 */
function reconstructAllPaths(
  target: string,
  source: string,
  parents: Map<string, Array<{ parentId: string; relType: string }>>,
  maxPaths: number
): string[][] {
  const result: string[][] = [];
  
  function dfs(current: string, path: string[]) {
    if (result.length >= maxPaths) return;
    
    if (current === source) {
      result.push([...path]);
      return;
    }
    
    const parentList = parents.get(current);
    if (!parentList) return;
    
    for (const p of parentList) {
      path.unshift(p.parentId);
      dfs(p.parentId, path);
      path.shift();
      if (result.length >= maxPaths) break;
    }
  }
  
  dfs(target, [target]);
  return result;
}

/**
 * Build path object with person details and relationships
 */
async function buildPathObject(
  pathIds: string[],
  parentsA: Map<string, Array<{ parentId: string; relType: string }>>,
  parentsB: Map<string, Array<{ parentId: string; relType: string }>>,
  personAId: string,
  meetPoint: string
): Promise<{
  path: { personId: string; name: string; gender: string }[];
  relationships: { from: string; to: string; type: string; label: string }[];
  depth: number;
}> {
  // Batch load person details
  const { data: persons } = await supabaseAdmin
    .from('persons')
    .select('id, name, gender')
    .in('id', pathIds);

  const personMap = new Map((persons || []).map((p: any) => [p.id, p]));

  const path = pathIds.map(id => {
    const p = personMap.get(id);
    return {
      personId: id,
      name: p?.name || 'Unknown',
      gender: p?.gender || 'other',
    };
  });

  // Build relationships from path
  const relationships: { from: string; to: string; type: string; label: string }[] = [];
  for (let i = 0; i < pathIds.length - 1; i++) {
    const from = pathIds[i];
    const to = pathIds[i + 1];
    
    // Find the relationship type from parent maps
    let relType = 'UNKNOWN';
    const parents = parentsA.get(to) || parentsB.get(to) || [];
    for (const p of parents) {
      if (p.parentId === from) {
        relType = p.relType;
        break;
      }
    }
    
    relationships.push({
      from,
      to,
      type: relType,
      label: humanReadableRelType(relType),
    });
  }

  return {
    path,
    relationships,
    depth: pathIds.length - 1,
  };
}

/** Flip a relationship type to its reverse direction */
function flipRelationshipType(type: string): string {
  switch (type) {
    case 'FATHER_OF': return 'CHILD_OF';
    case 'MOTHER_OF': return 'CHILD_OF';
    case 'PARENT_OF': return 'CHILD_OF';
    case 'CHILD_OF': return 'PARENT_OF';
    case 'SPOUSE_OF': return 'SPOUSE_OF';
    case 'SIBLING_OF': return 'SIBLING_OF';
    default: return type;
  }
}

/** Convert relationship type to human-readable label */
function humanReadableRelType(type: string): string {
  switch (type) {
    case 'FATHER_OF': return 'Father of';
    case 'MOTHER_OF': return 'Mother of';
    case 'PARENT_OF': return 'Parent of';
    case 'CHILD_OF': return 'Child of';
    case 'SPOUSE_OF': return 'Spouse of';
    case 'SIBLING_OF': return 'Sibling of';
    default: return type;
  }
}
