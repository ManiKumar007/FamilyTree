/**
 * Relationship Calculator Service
 * Converts a relationship path into natural language descriptions
 */

export interface RelationshipPath {
  personId: string;
  relationshipType: string; // FATHER_OF, MOTHER_OF, etc.
}

export interface CalculatedRelationship {
  description: string; // e.g., "paternal grandfather"
  category: 'immediate' | 'extended' | 'distant' | 'non-blood';
  generationsUp: number;
  generationsDown: number;
  isBloodRelation: boolean;
  geneticSimilarity?: number; // percentage (0-50)
}

/**
 * Calculate natural language relationship from a path
 */
export function calculateRelationship(
  path: RelationshipPath[],
  startGender: string,
  endGender: string
): CalculatedRelationship {
  if (path.length === 0) {
    return {
      description: 'yourself',
      category: 'immediate',
      generationsUp: 0,
      generationsDown: 0,
      isBloodRelation: true,
      geneticSimilarity: 50,
    };
  }

  // Single hop relationships
  if (path.length === 1) {
    return calculateDirectRelationship(path[0].relationshipType, endGender);
  }

  // Track generations and relationship type
  let upGenerations = 0;
  let downGenerations = 0;
  let marriageSteps = 0;
  let isBlood = true;
  let side: 'paternal' | 'maternal' | 'mixed' = 'mixed';

  for (let i = 0; i < path.length; i++) {
    const relType = path[i].relationshipType;

    if (relType === 'SPOUSE_OF') {
      marriageSteps++;
      isBlood = false;
    } else if (relType === 'FATHER_OF' || relType === 'MOTHER_OF' || relType === 'PARENT_OF') {
      upGenerations++;
      if (i === 0) {
        side = relType === 'FATHER_OF' ? 'paternal' : relType === 'MOTHER_OF' ? 'maternal' : 'mixed';
      }
    } else if (relType === 'CHILD_OF') {
      downGenerations++;
    } else if (relType === 'SIBLING_OF') {
      // Sibling is same generation
    }
  }

  const description = buildRelationshipDescription(
    path,
    upGenerations,
    downGenerations,
    marriageSteps,
    side,
    endGender
  );

  const category = categorizeRelationship(upGenerations, downGenerations, marriageSteps);
  const geneticSimilarity = calculateGeneticSimilarity(upGenerations, downGenerations, marriageSteps, isBlood);

  return {
    description,
    category,
    generationsUp: upGenerations,
    generationsDown: downGenerations,
    isBloodRelation: isBlood,
    geneticSimilarity,
  };
}

function calculateDirectRelationship(relType: string, gender: string): CalculatedRelationship {
  const genderSpecific = (male: string, female: string, other: string) =>
    gender === 'male' ? male : gender === 'female' ? female : other;

  const relationships: Record<string, { desc: string; category: any; up: number; down: number; blood: boolean; genetic: number }> = {
    FATHER_OF: { desc: genderSpecific('son', 'daughter', 'child'), category: 'immediate', up: 0, down: 1, blood: true, genetic: 50 },
    MOTHER_OF: { desc: genderSpecific('son', 'daughter', 'child'), category: 'immediate', up: 0, down: 1, blood: true, genetic: 50 },
    PARENT_OF: { desc: genderSpecific('son', 'daughter', 'child'), category: 'immediate', up: 0, down: 1, blood: true, genetic: 50 },
    CHILD_OF: { desc: genderSpecific('father', 'mother', 'parent'), category: 'immediate', up: 1, down: 0, blood: true, genetic: 50 },
    SPOUSE_OF: { desc: genderSpecific('husband', 'wife', 'spouse'), category: 'immediate', up: 0, down: 0, blood: false, genetic: 0 },
    SIBLING_OF: { desc: genderSpecific('brother', 'sister', 'sibling'), category: 'immediate', up: 0, down: 0, blood: true, genetic: 50 },
  };

  const rel = relationships[relType] || { desc: 'relative', category: 'extended', up: 0, down: 0, blood: true, genetic: 0 };

  return {
    description: rel.desc,
    category: rel.category,
    generationsUp: rel.up,
    generationsDown: rel.down,
    isBloodRelation: rel.blood,
    geneticSimilarity: rel.genetic,
  };
}

function buildRelationshipDescription(
  path: RelationshipPath[],
  upGens: number,
  downGens: number,
  marriages: number,
  side: 'paternal' | 'maternal' | 'mixed',
  endGender: string
): string {
  const genderize = (male: string, female: string, neutral: string) =>
    endGender === 'male' ? male : endGender === 'female' ? female : neutral;

  // Pattern matching for common relationships
  const pathStr = path.map(p => p.relationshipType).join('-');

  // Grandparents
  if (pathStr === 'FATHER_OF-FATHER_OF') return 'paternal grandfather';
  if (pathStr === 'FATHER_OF-MOTHER_OF') return 'paternal grandmother';
  if (pathStr === 'MOTHER_OF-FATHER_OF') return 'maternal grandfather';
  if (pathStr === 'MOTHER_OF-MOTHER_OF') return 'maternal grandmother';
  if (upGens === 2 && downGens === 0 && marriages === 0) return genderize('grandfather', 'grandmother', 'grandparent');

  // Great-grandparents
  if (upGens === 3 && downGens === 0 && marriages === 0) {
    const prefix = side === 'paternal' ? 'paternal ' : side === 'maternal' ? 'maternal ' : '';
    return prefix + genderize('great-grandfather', 'great-grandmother', 'great-grandparent');
  }
  if (upGens > 3 && downGens === 0 && marriages === 0) {
    const greats = 'great-'.repeat(upGens - 2);
    return genderize(`${greats}grandfather`, `${greats}grandmother`, `${greats}grandparent`);
  }

  // Grandchildren
  if (upGens === 0 && downGens === 2 && marriages === 0) return genderize('grandson', 'granddaughter', 'grandchild');
  if (upGens === 0 && downGens === 3 && marriages === 0) return genderize('great-grandson', 'great-granddaughter', 'great-grandchild');
  if (upGens === 0 && downGens > 3 && marriages === 0) {
    const greats = 'great-'.repeat(downGens - 2);
    return genderize(`${greats}grandson`, `${greats}granddaughter`, `${greats}grandchild`);
  }

  // Aunts/Uncles (parent's sibling)
  if (pathStr.match(/^(FATHER_OF|MOTHER_OF|PARENT_OF)-SIBLING_OF$/)) {
    const prefix = path[0].relationshipType === 'FATHER_OF' ? 'paternal ' : path[0].relationshipType === 'MOTHER_OF' ? 'maternal ' : '';
    return prefix + genderize('uncle', 'aunt', 'aunt/uncle');
  }

  // Nieces/Nephews (sibling's child)
  if (pathStr === 'SIBLING_OF-FATHER_OF' || pathStr === 'SIBLING_OF-MOTHER_OF' || pathStr === 'SIBLING_OF-PARENT_OF') {
    return genderize('nephew', 'niece', 'nibling');
  }

  // Cousins (calculated by cousin degree and removal)
  const cousinMatch = matchCousinPattern(path);
  if (cousinMatch) {
    const { degree, removal } = cousinMatch;
    if (degree === 1 && removal === 0) return 'cousin';
    if (degree === 1 && removal === 1) return 'first cousin once removed';
    if (degree === 1 && removal === 2) return 'first cousin twice removed';
    if (degree === 2 && removal === 0) return 'second cousin';
    if (degree === 2 && removal === 1) return 'second cousin once removed';
    if (degree === 3 && removal === 0) return 'third cousin';
    
    const degreeStr = degree === 1 ? 'first' : degree === 2 ? 'second' : degree === 3 ? 'third' : `${degree}th`;
    const removalStr = removal === 0 ? '' : removal === 1 ? ' once removed' : removal === 2 ? ' twice removed' : ` ${removal} times removed`;
    return `${degreeStr} cousin${removalStr}`;
  }

  // In-laws (via spouse)
  if (marriages > 0) {
    // Parent-in-law
    if (pathStr === 'SPOUSE_OF-FATHER_OF') return 'father-in-law';
    if (pathStr === 'SPOUSE_OF-MOTHER_OF') return 'mother-in-law';
    if (pathStr === 'SPOUSE_OF-PARENT_OF') return 'parent-in-law';

    // Child-in-law
    if (pathStr === 'FATHER_OF-SPOUSE_OF' || pathStr === 'MOTHER_OF-SPOUSE_OF' || pathStr === 'PARENT_OF-SPOUSE_OF') {
      return genderize('son-in-law', 'daughter-in-law', 'child-in-law');
    }

    // Sibling-in-law
    if (pathStr === 'SPOUSE_OF-SIBLING_OF') return genderize('brother-in-law', 'sister-in-law', 'sibling-in-law');
    if (pathStr === 'SIBLING_OF-SPOUSE_OF') return genderize('brother-in-law', 'sister-in-law', 'sibling-in-law');

    // Step-relations
    if (pathStr.includes('SPOUSE_OF') && upGens > 0) {
      return `step-${genderize('father', 'mother', 'parent')}'s relative`;
    }

    return 'relative by marriage';
  }

  // Default: describe by generation distance
  if (upGens > 0 && downGens === 0) {
    return `ancestor (${upGens} generation${upGens === 1 ? '' : 's'} up)`;
  }
  if (downGens > 0 && upGens === 0) {
    return `descendant (${downGens} generation${downGens === 1 ? '' : 's'} down)`;
  }
  if (upGens > 0 && downGens > 0) {
    return `distant relative (${upGens} up, ${downGens} down)`;
  }

  return 'relative';
}

/**
 * Match cousin pattern: Up to common ancestor, then down to target
 * Cousin degree = min(up, down) - 1
 * Removal = abs(up - down)
 */
function matchCousinPattern(path: RelationshipPath[]): { degree: number; removal: number } | null {
  let upSteps = 0;
  let downSteps = 0;
  let foundPeak = false;

  for (const step of path) {
    const rel = step.relationshipType;
    if (rel === 'FATHER_OF' || rel === 'MOTHER_OF' || rel === 'PARENT_OF') {
      if (foundPeak) return null; // Can't go up after going down
      upSteps++;
    } else if (rel === 'CHILD_OF') {
      foundPeak = true;
      downSteps++;
    } else if (rel === 'SIBLING_OF') {
      // Sibling step is allowed at peak only
      if (downSteps > 0) return null;
      foundPeak = true;
    } else if (rel === 'SPOUSE_OF') {
      return null; // Cousins are blood relations
    }
  }

  if (upSteps === 0 || (downSteps === 0 && upSteps < 2)) return null;

  const degree = Math.min(upSteps, downSteps + 1) - 1;
  const removal = Math.abs(upSteps - (downSteps + 1));

  return degree >= 1 ? { degree, removal } : null;
}

function categorizeRelationship(up: number, down: number, marriages: number): 'immediate' | 'extended' | 'distant' | 'non-blood' {
  if (marriages > 0 && up === 0 && down === 0) return 'non-blood';
  if (up <= 1 && down <= 1) return 'immediate';
  if (up <= 2 && down <= 2) return 'extended';
  return 'distant';
}

function calculateGeneticSimilarity(up: number, down: number, marriages: number, isBlood: boolean): number {
  if (!isBlood || marriages > 0) return 0;

  // Each generation halves genetic similarity
  const totalGenerations = up + down;
  if (totalGenerations === 0) return 50; // Parent-child or self
  if (totalGenerations === 1) return 50; // Direct parent/child
  if (totalGenerations === 2 && up === 0 && down === 2) return 25; // Grandparent-grandchild
  if (totalGenerations === 2) return 25; // Siblings, grandparent-grandchild

  // General formula: 50 / (2^generations) but cousins share common ancestor
  // For cousins: similarity = 50 / (2^(degree + 1))
  const similarity = 50 / Math.pow(2, totalGenerations - 1);
  return Math.max(0.1, Math.min(50, similarity)); // Cap between 0.1% and 50%
}
