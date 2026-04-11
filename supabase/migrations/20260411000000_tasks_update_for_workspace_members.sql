-- TaskHive: allow authenticated workspace members to UPDATE tasks (e.g. Kanban status).
-- Run this in Supabase Dashboard → SQL Editor if moving tasks fails with "No row was updated".
--
-- Typical cause: RLS is ON for `tasks` but there is no UPDATE policy (or it only allows the creator).

-- 1) Adjust policy name if you already use one; drop first to avoid duplicates.
DROP POLICY IF EXISTS "tasks_update_workspace_members" ON public.tasks;

CREATE POLICY "tasks_update_workspace_members"
  ON public.tasks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.workspace_members wm
      WHERE wm.workspace_id = tasks.workspace_id
        AND wm.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.workspace_members wm
      WHERE wm.workspace_id = tasks.workspace_id
        AND wm.user_id = auth.uid()
    )
  );

-- If updates still return 0 rows, ensure you also have SELECT on tasks for members
-- (PostgREST may need to read the row after update). Example:
--
-- DROP POLICY IF EXISTS "tasks_select_workspace_members" ON public.tasks;
-- CREATE POLICY "tasks_select_workspace_members"
--   ON public.tasks FOR SELECT TO authenticated
--   USING (
--     EXISTS (
--       SELECT 1 FROM public.workspace_members wm
--       WHERE wm.workspace_id = tasks.workspace_id AND wm.user_id = auth.uid()
--     )
--   );
