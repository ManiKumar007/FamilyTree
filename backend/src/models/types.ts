import { z } from 'zod';

export const GenderEnum = z.enum(['male', 'female', 'other']);
export const MaritalStatusEnum = z.enum(['single', 'married', 'divorced', 'widowed']);
export const RelationshipTypeEnum = z.enum([
  'FATHER_OF', 'MOTHER_OF', 'PARENT_OF', 'CHILD_OF', 'SPOUSE_OF', 'SIBLING_OF'
]);
export const LifeEventTypeEnum = z.enum([
  'birth', 'death', 'marriage', 'engagement', 'divorce',
  'naming_ceremony', 'thread_ceremony', 'graduation', 'retirement',
  'migration', 'achievement', 'medical', 'religious', 'custom'
]);
export const ForumPostTypeEnum = z.enum([
  'story', 'recipe', 'photo_album', 'announcement', 'discussion', 'memory'
]);
export const DocumentTypeEnum = z.enum([
  'photo', 'birth_certificate', 'marriage_certificate', 'death_certificate',
  'aadhaar', 'passport', 'property_doc', 'other'
]);
export const NotificationTypeEnum = z.enum([
  'birthday_reminder', 'anniversary_reminder', 'death_anniversary',
  'new_member_added', 'merge_request', 'invite_accepted',
  'forum_comment', 'forum_like', 'system', 'custom'
]);
export const ActivityTypeEnum = z.enum([
  'person_added', 'person_updated', 'relationship_added',
  'photo_uploaded', 'profile_claimed', 'member_joined',
  'forum_post', 'life_event_added', 'document_uploaded'
]);
export const CalendarEventTypeEnum = z.enum([
  'birthday', 'anniversary', 'death_anniversary', 'festival',
  'puja', 'wedding', 'engagement', 'reunion', 'custom'
]);

export interface Person {
  id: string;
  username: string | null;
  name: string;
  given_name: string;
  surname: string | null;
  date_of_birth: string | null;
  date_of_death: string | null;
  place_of_death: string | null;
  is_alive: boolean;
  gender: 'male' | 'female' | 'other';
  photo_url: string | null;
  phone: string;
  email: string | null;
  occupation: string | null;
  community: string | null;
  gotra: string | null;
  sub_caste: string | null;
  nakshatra: string | null;
  rashi: string | null;
  native_place: string | null;
  ancestral_village: string | null;
  kula_devata: string | null;
  pravara: string | null;
  city: string | null;
  state: string | null;
  marital_status: 'single' | 'married' | 'divorced' | 'widowed';
  wedding_date: string | null;
  is_profile_public: boolean;
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
  type: 'FATHER_OF' | 'MOTHER_OF' | 'PARENT_OF' | 'CHILD_OF' | 'SPOUSE_OF' | 'SIBLING_OF';
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

export interface LifeEvent {
  id: string;
  person_id: string;
  event_type: string;
  title: string;
  description: string | null;
  event_date: string | null;
  event_place: string | null;
  photo_url: string | null;
  metadata: Record<string, any>;
  created_by_user_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface ForumPost {
  id: string;
  author_user_id: string;
  post_type: string;
  title: string;
  content: string | null;
  is_pinned: boolean;
  likes_count: number;
  comments_count: number;
  media?: ForumMedia[];
  author_name?: string;
  created_at: string;
  updated_at: string;
}

export interface ForumMedia {
  id: string;
  post_id: string;
  media_url: string;
  media_type: string;
  caption: string | null;
  sort_order: number;
  created_at: string;
}

export interface ForumComment {
  id: string;
  post_id: string;
  author_user_id: string;
  parent_comment_id: string | null;
  content: string;
  likes_count: number;
  author_name?: string;
  created_at: string;
  updated_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  notification_type: string;
  title: string;
  message: string | null;
  data: Record<string, any>;
  is_read: boolean;
  created_at: string;
}

export interface ActivityEntry {
  id: string;
  user_id: string;
  activity_type: string;
  title: string;
  description: string | null;
  entity_id: string | null;
  entity_type: string | null;
  metadata: Record<string, any>;
  created_at: string;
}

export interface FamilyEvent {
  id: string;
  created_by_user_id: string;
  event_type: string;
  title: string;
  description: string | null;
  event_date: string;
  is_recurring: boolean;
  recurrence_type: string;
  person_id: string | null;
  reminder_days_before: number;
  metadata: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface PersonDocument {
  id: string;
  person_id: string;
  doc_type: string;
  title: string;
  description: string | null;
  file_url: string;
  file_size_bytes: number | null;
  mime_type: string | null;
  is_private: boolean;
  uploaded_by_user_id: string | null;
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
