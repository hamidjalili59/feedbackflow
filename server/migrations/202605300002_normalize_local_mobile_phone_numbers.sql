-- Normalize legacy locally-entered Iranian mobile numbers created from the admin UI.
-- The client login screen sends Iranian mobiles as +98..., so keeping 09... in users.phone
-- made newly-created students/parents unable to sign in after logout.
update users u
   set phone = '+98' || substring(u.phone from 2),
       updated_at = now()
 where u.deleted_at is null
   and u.phone ~ '^09[0-9]{9}$'
   and not exists (
     select 1
       from users x
      where x.id <> u.id
        and x.deleted_at is null
        and x.phone = '+98' || substring(u.phone from 2)
   );

update users u
   set phone = '+' || u.phone,
       updated_at = now()
 where u.deleted_at is null
   and u.phone ~ '^989[0-9]{9}$'
   and not exists (
     select 1
       from users x
      where x.id <> u.id
        and x.deleted_at is null
        and x.phone = '+' || u.phone
   );
