from aws_embedded_metrics import metric_scope


@metric_scope
def handler(event, _context, metrics):
    print("INIT HANDLER")
    glue_job_name = event["detail"]["jobName"]
    glue_job_run_id = event["detail"]["jobRunId"]

    print(f"NAME {glue_job_name}")
    metrics.set_namespace(f"GlueBasicMetrics")
    metrics.set_dimensions(
        {"JobName": glue_job_name}, {"JobName": glue_job_name, "JobRunId": glue_job_run_id}
    )

    if event["detail-type"] == "Glue Job State Change":
        state = event["detail"]["state"]
        print(f"State {state}")

        if state not in ["SUCCEEDED", "FAILED", "TIMEOUT", "STOPPED", "RUNNING"]:
            raise AttributeError("State is not supported.")

        metrics.put_metric(key=state.capitalize(), value=1, unit="Count")

        if state == "SUCCEEDED":
            metrics.put_metric(key="Failed", value=0, unit="Count")
        else:
            metrics.put_metric(key="Succeeded", value=0, unit="Count")
