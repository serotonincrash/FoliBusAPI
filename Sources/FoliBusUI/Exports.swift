//
//  Exports.swift
//  FoliBusAPI
//

/// `FoliBusUI` re-exports the entire `FoliBusAPI` surface: a single
/// `import FoliBusUI` also provides `FoliClient`, the `Foli` model
/// namespace, and `FoliClientConfiguration`, with no second import needed.
///
/// `@_exported` is an underscored attribute without official support, but it
/// is stable in practice and the established way to build a facade module.
@_exported import FoliBusAPI
