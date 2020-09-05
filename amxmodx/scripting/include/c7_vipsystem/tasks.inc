#define TASK_USER_FLASHED 6700

public task_stop(task_id) {
  if (task_exists(task_id)) remove_task(task_id);
}
