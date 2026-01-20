-- Remove the trigger completely
-- This will eliminate the source of duplicate key errors

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

SELECT 'Trigger removed successfully' as status;
