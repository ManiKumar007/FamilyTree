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
 * Supports filtering by occupation, marital status, and name.
 *
 * Uses batch-loading: 2 queries per depth level instead of 1 per person.
 */
export async function searchInCircles(params: {
  personId: string;
  maxDepth: number;
  query?: string;
  occupation?: string;
  maritalStatus?: string;
}): Promise<SearchResult[]> {
  const { personId, maxDepth, query, occupation, maritalStatus } = params;

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
        (person.occupation?.toLowerCase().includes(q) ?? false)
      );
    }

    if (occupation) {
      matches = matches && (person.occupation?.toLowerCase().includes(occupation.toLowerCase()) ?? false);
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
