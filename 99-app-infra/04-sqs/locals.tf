locals {
  sqs_queues = {
    sweep_request = {
      name        = "${var.project}-${var.env}-sweep-request-queue.fifo"
      description = "Card Channel to Invest Channel sweep request FIFO queue"
      role        = "request"
    }

    sweep_result = {
      name        = "${var.project}-${var.env}-sweep-result-queue.fifo"
      description = "Invest Channel to Card Channel sweep result FIFO queue"
      role        = "result"
    }
  }
}
