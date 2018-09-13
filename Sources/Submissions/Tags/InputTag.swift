import TemplateKit

public final class InputTag: TagRenderer {
    struct InputData: Encodable {
        let key: String
        let value: String?
        let label: String?
        let isRequired: Bool
        let errors: [String]
        let hasErrors: Bool
        let placeholder: String?
        let helpText: String?
    }

    public convenience init(templatePath: String) {
        self.init { tagContext, inputData in
            try tagContext.requireNoBody()
            return try tagContext
                .container
                .make(TemplateRenderer.self)
                .render(templatePath, inputData)
                .map { .data($0.data) }
        }
    }

    typealias Render = (TagContext, InputData) throws -> Future<TemplateData>
    let render: Render

    init(render: @escaping Render) {
        self.render = render
    }

    public func render(tag: TagContext) throws -> Future<TemplateData> {
        let data = try tag.submissionsData()

        let placeholder = tag.parameters[safe: 1]?.string
        let helpText = tag.parameters[safe: 2]?.string

        let inputData = InputData(
            key: data.key,
            value: data.value,
            label: data.label,
            isRequired: data.isRequired,
            errors: data.errors,
            hasErrors: data.hasErrors,
            placeholder: placeholder,
            helpText: helpText
        )

        return try render(tag, inputData)
    }
}

// MARK: Move me

import Vapor

extension ViewRenderer {
    public func render<E>(_ path: String, _ context: E, userInfo: [AnyHashable: Any] = [:], on req: Request) -> Future<View> where E: Encodable {
        var userInfo = userInfo
        userInfo[requestUserInfoKey] = req
        return render(path, context, userInfo: userInfo)
    }

    public func render(_ path: String, userInfo: [AnyHashable: Any] = [:], on req: Request) -> Future<View> {
        return render(path, Dictionary<String, String>(), userInfo: userInfo, on: req)
    }
}

extension TagContext {
    public var request: Request? {
        get {
            return context.userInfo[requestUserInfoKey] as? Request
        }
        set {
            context.userInfo[requestUserInfoKey] = newValue
        }
    }

    public func requireRequest() throws -> Request {
        guard let request = request else {
            throw SubmissionError.requestNotPassedIntoRender
        }
        return request
    }
}

private let requestUserInfoKey = "_submissions:request"
