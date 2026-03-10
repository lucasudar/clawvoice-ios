import Foundation

// MARK: - Client → Server

struct GeminiSetupMessage: Encodable {
    let setup: Setup

    struct Setup: Encodable {
        let model: String
        let generationConfig: GenerationConfig
        let systemInstruction: Content
        let tools: [Tool]

        enum CodingKeys: String, CodingKey {
            case model, tools
            case generationConfig = "generation_config"
            case systemInstruction = "system_instruction"
        }
    }

    struct GenerationConfig: Encodable {
        let responseModalities: [String]
        let speechConfig: SpeechConfig

        enum CodingKeys: String, CodingKey {
            case responseModalities = "response_modalities"
            case speechConfig = "speech_config"
        }
    }

    struct SpeechConfig: Encodable {
        let voiceConfig: VoiceConfig
        enum CodingKeys: String, CodingKey { case voiceConfig = "voice_config" }
    }

    struct VoiceConfig: Encodable {
        let prebuiltVoiceConfig: PrebuiltVoiceConfig
        enum CodingKeys: String, CodingKey { case prebuiltVoiceConfig = "prebuilt_voice_config" }
    }

    struct PrebuiltVoiceConfig: Encodable {
        let voiceName: String
        enum CodingKeys: String, CodingKey { case voiceName = "voice_name" }
    }

    struct Content: Encodable {
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String
    }

    struct Tool: Encodable {
        let functionDeclarations: [FunctionDeclaration]
        enum CodingKeys: String, CodingKey { case functionDeclarations = "function_declarations" }
    }

    struct FunctionDeclaration: Encodable {
        let name: String
        let description: String
        let parameters: Parameters
    }

    struct Parameters: Encodable {
        let type: String
        let properties: [String: Property]
        let required: [String]
    }

    struct Property: Encodable {
        let type: String
        let description: String
    }
}

struct GeminiAudioMessage: Encodable {
    let realtimeInput: RealtimeInput
    enum CodingKeys: String, CodingKey { case realtimeInput = "realtime_input" }

    struct RealtimeInput: Encodable {
        let mediaChunks: [MediaChunk]
        enum CodingKeys: String, CodingKey { case mediaChunks = "media_chunks" }
    }

    struct MediaChunk: Encodable {
        let data: String       // base64 PCM
        let mimeType: String
        enum CodingKeys: String, CodingKey { case data; case mimeType = "mime_type" }
    }
}

struct GeminiToolResponseMessage: Encodable {
    let toolResponse: ToolResponse
    enum CodingKeys: String, CodingKey { case toolResponse = "tool_response" }

    struct ToolResponse: Encodable {
        let functionResponses: [FunctionResponse]
        enum CodingKeys: String, CodingKey { case functionResponses = "function_responses" }
    }

    struct FunctionResponse: Encodable {
        let id: String
        let response: ResponseBody
    }

    struct ResponseBody: Encodable {
        let output: String
    }
}

// MARK: - Server → Client

struct GeminiServerMessage: Decodable {
    let setupComplete: AnyCodable?
    let serverContent: ServerContent?
    let toolCall: ToolCallPayload?

    enum CodingKeys: String, CodingKey {
        case setupComplete = "setupComplete"
        case serverContent = "serverContent"
        case toolCall      = "toolCall"
    }

    struct ServerContent: Decodable {
        let modelTurn: ModelTurn?
        let turnComplete: Bool?

        enum CodingKeys: String, CodingKey {
            case modelTurn    = "model_turn"
            case turnComplete = "turn_complete"
        }
    }

    struct ModelTurn: Decodable {
        let parts: [Part]
    }

    struct Part: Decodable {
        let text: String?
        let inlineData: InlineData?

        enum CodingKeys: String, CodingKey {
            case text
            case inlineData = "inline_data"
        }
    }

    struct InlineData: Decodable {
        let data: String      // base64
        let mimeType: String
        enum CodingKeys: String, CodingKey { case data; case mimeType = "mime_type" }
    }

    struct ToolCallPayload: Decodable {
        let functionCalls: [FunctionCall]
        enum CodingKeys: String, CodingKey { case functionCalls = "function_calls" }
    }

    struct FunctionCall: Decodable {
        let id: String
        let name: String
        let args: [String: String]
    }
}

// Helper to decode unknown objects
struct AnyCodable: Decodable {
    init(from decoder: Decoder) throws { _ = try? decoder.singleValueContainer() }
}
