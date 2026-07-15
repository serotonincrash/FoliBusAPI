//
//  Exports.swift
//  FoliBusAPI
//

/// FoliBusUI re-exports the entire FoliBusAPI surface so that a single
/// `import FoliBusUI` gives access to `FoliClient`, the `Foli` model
/// namespace, and configuration types without a second import.
///
/// Note: `@_exported` is an underscored, officially-unsupported attribute,
/// but it is stable in practice and widely used for exactly this
/// facade-module pattern. If it is ever removed, the fallback is asking
/// clients to add `import FoliBusAPI` alongside `import FoliBusUI`.
@_exported import FoliBusAPI
