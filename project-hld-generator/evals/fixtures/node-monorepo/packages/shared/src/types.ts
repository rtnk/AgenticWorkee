export interface Task {
  id: string;
  title: string;
  status: "todo" | "in-progress" | "done";
  assignee?: string;
}
