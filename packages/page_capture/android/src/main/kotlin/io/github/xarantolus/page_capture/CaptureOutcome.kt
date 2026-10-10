package io.github.xarantolus.page_capture

sealed interface CaptureOutcome {
    fun toMap(millis: Long): Map<String, Any?>

    class Success(
        private val bytes: Long,
        private val resources: Int,
        private val blocked: Int,
        private val removed: Int,
        private val consent: List<String>,
        private val finalUrl: String?,
        private val listsMissing: Boolean,
        private val phases: Map<String, Long>,
    ) : CaptureOutcome {
        override fun toMap(millis: Long) = mapOf(
            "ok" to true,
            "millis" to millis,
            "bytes" to bytes,
            "resources" to resources,
            "blocked" to blocked,
            "removed" to removed,
            "consent" to consent,
            "finalUrl" to finalUrl,
            "listsMissing" to listsMissing,
            "phases" to phases,
        )
    }

    class Failure(
        private val kind: String,
        private val message: String,
        private val httpStatus: Int? = null,
        private val contentType: String? = null,
    ) : CaptureOutcome {
        override fun toMap(millis: Long) = mapOf(
            "ok" to false,
            "millis" to millis,
            "error" to kind,
            "message" to message,
            "httpStatus" to httpStatus,
            "contentType" to contentType,
        )

        companion object {
            fun timeout(message: String) = Failure("timeout", message)
            fun network(message: String) = Failure("network", message)
            fun ssl() = Failure("ssl", "certificate rejected")
            fun http(status: Int) = Failure("http", "HTTP $status", httpStatus = status)
            fun tooLarge(bytes: Long) = Failure("tooLarge", "$bytes bytes")
            fun unsupported(contentType: String) =
                Failure("unsupportedContent", contentType, contentType = contentType)
            fun cancelled() = Failure("cancelled", "cancelled")
            fun internal(message: String) = Failure("internal", message)
        }
    }
}
