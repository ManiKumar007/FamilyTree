import { supabaseAdmin } from '../config/supabase';
import { Person, Relationship, TreeNode, TreeResponse, SearchResult } from '../models/types';

/**
 * GraphService: handles family tree traversal using PostgreSQL recursive CTEs.
 */

/**
 * Get the full family tree for a person.
 * Returns all connected persons (unlimited depth) with their relationships.
 */
export async function getFullTree(personId: string): Promise<TreeResponse> {
  // Use a recursive CTE to find all connected persons
  const { data, error } = await supabaseAdmin.rpc('get_full_tree', {
    root_person_id: personId,
  });

  if (error) {
    // Fallback: use multiple queries if RPC not available
    return getFullTreeFallback(personId);
  }

  return { nodes: data, rootPersonId: personId };
}

/**
 * Fallback: build tree using iterative queries.
 * Works without a database function.
 */
async function getFullTreeFallback(personId: string): Promise<TreeResponse> {
  const visited = new Set<string>();
  const nodes: TreeNode[] = [];
  const queue: string[] = [personId];

  while (queue.length > 0) {
    const currentId = queue.shift()!;
    if (visited.has(currentId)) continue;
    visited.add(currentId);

    // Get person details
    const { data: person, error: personError } = await supabaseAdmin
      .from('persons')
      .select('*')
      .eq('id', currentId)
      .single();

    if (personError || !person) continue;

    // Get all relationships for this person
    const { data: relationships, error: relError } = await supabaseAdmin
      .from('relationships')
      .select('*')
      .eq('person_id', currentId);

    if (relError) continue;

    const rels = (relationships || []) as Relationship[];
    nodes.push({ person: person as Person, relationships: rels });

    // Add connected persons to queue
    for (const rel of rels) {
      if (!visited.has(rel.related_person_id)) {
        queue.push(rel.related_person_id);
      }
    }
  }

  return { nodes, rootPersonId: personId };
}

/**
 * Search for persons within N circles (hops) of a starting person.
 * Supports filtering by occupation, marital status, and name.
 */
export async function searchInCircles(params: {
  personId: string;
  maxDepth: number;
  query?: string;
  occupation?: string;
  maritalStatus?: string;
}): Promise<SearchResult[]> {
  const { personId, maxDepth, query, occupation, maritalStatus } = params;

  // Build a raw SQL query with recursive CTE for N-circle traversal
  // We use supabaseAdmin.rpc or raw query
  const visited = new Set<string>();
  const results: SearchResult[] = [];
  const queue: { id: string; depth: number; path: string[] }[] = [
    { id: personId, depth: 0, path: [personId] },
  ];

  while (queue.length > 0) {
    const current = queue.shift()!;
    if (visited.has(current.id) || current.depth > maxDepth) continue;
    visited.add(current.id);

    // Get person details
    const { data: person } = await supabaseAdmin
      .from('persons')
      .select('*')
      .eq('id', current.id)
      .single();

    if (!person) continue;

    // Apply filters (skip the root person)
    if (current.depth > 0) {
      const p = person as Person;
      let matches = true;

      if (query) {
        const q = query.toLowerCase();
        matches = matches && (
          p.name.toLowerCase().includes(q) ||
          (p.occupation?.toLowerCase().includes(q) ?? false)
        );
      }

      if (occupation) {
        matches = matches && (p.occupation?.toLowerCase().includes(occupation.toLowerCase()) ?? false);
      }

      if (maritalStatus) {
        matches = matches && p.marital_status === maritalStatus;
      }

      if (matches) {
        results.push({
          person: p,
          depth: current.depth,
          path: current.path,
        });
      }
    }

    // If we haven't reached max depth, get connected persons
    if (current.depth < maxDepth) {
      const { data: relationships } = await supabaseAdmin
        .from('relationships')
        .select('related_person_id')
        .eq('person_id', current.id);

      if (relationships) {
        for (const rel of relationships) {
          if (!visited.has(rel.related_person_id)) {
            queue.push({
              id: rel.related_person_id,
              depth: current.depth + 1,
              path: [...current.path, rel.related_person_id],
            });
          }
        }
      }
    }
  }

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
  const { data } = await supabaseAdmin
    .from('persons')
    .select('id, name')
    .in('id', personIds);

  if (!data) return [];

  const nameMap = new Map(data.map((p: any) => [p.id, p.name]));
  return personIds.map(id => nameMap.get(id) || 'Unknown');
}
