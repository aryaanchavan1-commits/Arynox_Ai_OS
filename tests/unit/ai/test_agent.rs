#[cfg(test)]
mod tests {
    use arynox_ai_agent::AIAgent;

    #[tokio::test]
    async fn test_create_agent_task() {
        let agent = AIAgent::new();
        let task = agent.search_files("*.rs", "/tmp").await;
        assert!(!task.is_empty());
    }

    #[tokio::test]
    async fn test_task_confirmation_flow() {
        let mut agent = AIAgent::new();
        let task = agent.organize_files("/tmp/test_organize", "type").await;
        assert_eq!(task.status, "pending");

        let pending = agent.get_pending_confirmations();
        assert_eq!(pending.len(), 1);

        let result = agent.confirm_task(task.id, true).await;
        assert!(result.is_some());
        let result = result.unwrap();
        assert!(result["status"] == "completed" || result["status"] == "running");
    }

    #[tokio::test]
    async fn test_task_denied() {
        let mut agent = AIAgent::new();
        let task = agent.delete_files(vec!["/tmp/test_file.txt"]).await;
        let result = agent.confirm_task(task.id, false).await;
        assert!(result.is_some());
        assert_eq!(result.unwrap()["status"], "denied");
    }
}
