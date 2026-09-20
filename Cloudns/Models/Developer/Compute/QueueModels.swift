import Foundation

// MARK: - Cloudflare Queues Models

public struct CFQueue: Codable, Identifiable, Equatable, Sendable {
    public var id: String {
        queueId ?? queueName
    }

    public let queueId: String?
    public let queueName: String
    public let createdOn: String?
    public let modifiedOn: String?
    public let settings: CFQueueSettings?
    public let producers: [CFQueueProducer]?
    public let consumers: [CFQueueConsumer]?

    enum CodingKeys: String, CodingKey {
        case queueId = "queue_id"
        case queueName = "queue_name"
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
        case settings, producers, consumers
    }

    public init(queueId: String?, queueName: String, createdOn: String? = nil, modifiedOn: String? = nil, settings: CFQueueSettings? = nil, producers: [CFQueueProducer]? = nil, consumers: [CFQueueConsumer]? = nil) {
        self.queueId = queueId
        self.queueName = queueName
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
        self.settings = settings
        self.producers = producers
        self.consumers = consumers
    }
}

public struct CFQueueSettings: Codable, Equatable, Sendable {
    public let deliveryDelay: Int?
    public let messageRetentionPeriod: Int?
    public let deliveryPaused: Bool?

    enum CodingKeys: String, CodingKey {
        case deliveryDelay = "delivery_delay"
        case messageRetentionPeriod = "message_retention_period"
        case deliveryPaused = "delivery_paused"
    }
}

public struct CFQueueProducer: Codable, Equatable, Identifiable, Sendable {
    public var id: String {
        script ?? "\(service ?? "")-\(environment ?? "")"
    }

    public let service: String?
    public let environment: String?
    public let script: String?
}

public struct CFQueueConsumer: Codable, Equatable, Identifiable, Sendable {
    public var id: String {
        consumerId ?? scriptName ?? "\(service ?? "")-\(environment ?? "")"
    }

    public let consumerId: String?
    public let service: String?
    public let environment: String?
    public let scriptName: String?
    public let type: String?
    public let deadLetterQueue: String?
    public let createdOn: String?
    public let settings: CFQueueConsumerSettings?

    enum CodingKeys: String, CodingKey {
        case consumerId = "consumer_id"
        case service, environment
        case scriptName = "script_name"
        case type
        case deadLetterQueue = "dead_letter_queue"
        case createdOn = "created_on"
        case settings
    }

    public init(
        consumerId: String? = nil,
        service: String? = nil,
        environment: String? = nil,
        scriptName: String? = nil,
        type: String? = "worker",
        deadLetterQueue: String? = nil,
        createdOn: String? = nil,
        settings: CFQueueConsumerSettings? = nil
    ) {
        self.consumerId = consumerId
        self.service = service
        self.environment = environment
        self.scriptName = scriptName
        self.type = type
        self.deadLetterQueue = deadLetterQueue
        self.createdOn = createdOn
        self.settings = settings
    }
}

public struct CFQueueConsumerSettings: Codable, Equatable, Sendable {
    public let batchSize: Int?
    public let maxBatchTimeout: Int?
    public let maxRetries: Int?
    public let maxWaitTimeMs: Int?
    public let retryDelay: Int?
    public let maxConcurrency: Int?

    enum CodingKeys: String, CodingKey {
        case batchSize = "batch_size"
        case maxBatchTimeout = "max_batch_timeout"
        case maxRetries = "max_retries"
        case maxWaitTimeMs = "max_wait_time_ms"
        case retryDelay = "retry_delay"
        case maxConcurrency = "max_concurrency"
    }

    public init(
        batchSize: Int? = 10,
        maxBatchTimeout: Int? = 5,
        maxRetries: Int? = 3,
        maxWaitTimeMs: Int? = nil,
        retryDelay: Int? = nil,
        maxConcurrency: Int? = nil
    ) {
        self.batchSize = batchSize
        self.maxBatchTimeout = maxBatchTimeout
        self.maxRetries = maxRetries
        self.maxWaitTimeMs = maxWaitTimeMs
        self.retryDelay = retryDelay
        self.maxConcurrency = maxConcurrency
    }
}

public struct CFQueueConsumerCreate: Codable, Sendable {
    public let service: String?
    public let environment: String?
    public let deadLetterQueue: String?
    public let type: String?
    public let settings: CFQueueConsumerSettings?

    enum CodingKeys: String, CodingKey {
        case service, environment
        case deadLetterQueue = "dead_letter_queue"
        case type, settings
    }

    public init(service: String?, environment: String? = nil, deadLetterQueue: String? = nil, type: String? = "worker", settings: CFQueueConsumerSettings? = nil) {
        self.service = service
        self.environment = environment
        self.deadLetterQueue = deadLetterQueue
        self.type = type
        self.settings = settings
    }
}

public struct CFQueueMetrics: Codable, Equatable, Sendable {
    public let messages: Int?
    public let delayedMessages: Int?
    public let activeConsumers: Int?

    enum CodingKeys: String, CodingKey {
        case messages
        case delayedMessages = "delayed_messages"
        case activeConsumers = "active_consumers"
    }
}

public struct CFQueueCreate: Codable, Sendable {
    public let queueName: String
    enum CodingKeys: String, CodingKey {
        case queueName = "queue_name"
    }

    public init(queueName: String) {
        self.queueName = queueName
    }
}

public struct CFQueueUpdate: Codable, Sendable {
    public let queueName: String?
    public let deliveryDelay: Int?
    public let messageRetentionPeriod: Int?
    public let deliveryPaused: Bool?

    enum CodingKeys: String, CodingKey {
        case queueName = "queue_name"
        case deliveryDelay = "delivery_delay"
        case messageRetentionPeriod = "message_retention_period"
        case deliveryPaused = "delivery_paused"
    }

    public init(queueName: String? = nil, deliveryDelay: Int? = nil, messageRetentionPeriod: Int? = nil, deliveryPaused: Bool? = nil) {
        self.queueName = queueName
        self.deliveryDelay = deliveryDelay
        self.messageRetentionPeriod = messageRetentionPeriod
        self.deliveryPaused = deliveryPaused
    }
}

public struct CFQueuePurge: Codable, Sendable {
    public let deleteMessagesPermanently: Bool
    enum CodingKeys: String, CodingKey {
        case deleteMessagesPermanently = "delete_messages_permanently"
    }

    public init(deleteMessagesPermanently: Bool = true) {
        self.deleteMessagesPermanently = deleteMessagesPermanently
    }
}
