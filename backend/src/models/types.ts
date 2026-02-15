import { z } from 'zod';

export const GenderEnum = z.enum(['male', 'female', 'other']);
export const MaritalStatusEnum = z.enum(['single', 'married', 'divorced', 'widowed']);
export const RelationshipTypeEnum = z.enum([
  'FATHER_OF', 'MOTHER_OF', 'CHILD_OF', 'SPOUSE_OF', 'SIBLING_OF'
]);

export interface Person {
  id: string;
  name: string;
  date_of_birth: string | null;
  gender: 'male' | 'female' | 'other';
  photo_url: string | null;
  phone: string;
  email: string | null;
  occupation: string | null;
  community: string | null;
  city: string | null;
  state: string | null;
  marital_status: 'single' | 'married' | 'divorced' | 'widowed';
  wedding_date: string | null;
  created_by_user_id: string | null;
  auth_user_id: string | null;
  verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface Relationship {
  id: string;
  person_id: string;
  related_person_id: string;
  type: 'FATHER_OF' | 'MOTHER_OF' | 'CHILD_OF' | 'SPOUSE_OF' | 'SIBLING_OF';
  created_by_user_id: string | null;
  created_at: string;
}

export interface MergeRequest {
  id: string;
  requester_user_id: string;
  target_person_id: string;
  matched_person_id: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  field_conflicts: Record<string, { target: any; matched: any }>;
  resolved_by_user_id: string | null;
  resolved_at: string | null;
  created_at: string;
}

export interface TreeNode {
  person: Person;
  relationships: Relationship[];
}

export interface TreeResponse {
  nodes: TreeNode[];
  rootPersonId: string;
}

export interface SearchResult {
  person: Person;
  depth: number;
  path: string[]; // Array of person IDs forming the connection path
}
