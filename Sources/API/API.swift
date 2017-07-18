// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================


import Foundation

/// Main entry point of the library, used to control item download and get their playback URL.
public protocol ContentManager: class {
    
    /// Set download base path. Must be set before start(), otherwise has no effect.
    var storagePath: URL { get set }
    
    /// Set max concurrent downloads. This relates to download chunks, not DTGItems.
    /// Must be set before start() is called, otherwise has no effect.
    var maxConcurrentDownloads: Int { get set }
    
    /// Delegate that will receive download events.
    var itemDelegate: DTGItemDelegate? { get set } // FIXME: if no other Delegate in the future change the name to `delegate`
    
    /// Start the content manager. This also starts the playback server.
    func start() throws
    
    /// Stop the content manager, including the playback server.
    func stop()
    
    /// Resume downloading of items that were in progress when stop() was called.
    func resumeInterruptedItems() throws
    
    /// Return all items in the specified state.
    func itemsByState(_ state: DTGItemState) -> [DTGItem]
    
    /// Find an existing item.
    /// - Parameter id: the item's unique id.
    /// - Returns: an item, or nil if not found.
    func itemById(_ id: String) -> DTGItem?
    
    /// Add a new item.
    /// - Parameters:
    ///     - id: a unique id for the new item
    ///     - url: the remote URL of the item.
    /// - Returns: the newly allocated item or nil if already exists.
    func addItem(id: String, url: URL) -> DTGItem?
    
    /// Load metadata for the given item id.
    /// - Parameters:
    ///     - id: the item's unique id.
    ///     - callback: block that takes the updated item.
    /// - Throws: DTGError.itemNotFound
    func loadItemMetadata(id: String, preferredVideoBitrate: Int?, callback: @escaping (DTGItem?, DTGVideoTrack?, Error?) -> Void) throws
    
    /// Start or resume item download.
    /// - Throws: DTGError.itemNotFound
    func startItem(id: String) throws
    
    /// Pause downloading an item.
    /// - Throws: DTGError.itemNotFound
    func pauseItem(id: String) throws
    
    /// Remove an existing item from storage, deleting all related files.
    /// - Throws: DTGError.itemNotFound
    func removeItem(id: String) throws
    
    /// Get a playable URL for an item.
    /// - Returns: a playback URL, or nil.
    /// - Throws: DTGError.itemNotFound
    func itemPlaybackUrl(id: String) throws -> URL?
    
    
    /// Handles events of a background session waiting to be processed.
    ///
    /// - Parameters:
    ///   - identifier: The background url session identifier.
    ///   - completionHandler: the completionHandler to call when finished handling the events.
    func handleEventsForBackgroundURLSession(identifier: String, completionHandler: @escaping () -> Void)
}

/// Delegate that will receive download events.
public protocol DTGItemDelegate: class {
    /// Item download has failed.
    func item(id: String, didFailWithError error: Error)
    
    /// Some data was downloaded for the item. 
    func item(id: String, didDownloadData totalBytesDownloaded: Int64, totalBytesEstimated: Int64?)
    
    /// Item has changed state.
    func item(id: String, didChangeToState newState: DTGItemState)
}

/// A downloadable item.
public protocol DTGItem {
    /// The item's unique id.
    var id: String { get }
    
    /// The items's remote URL.
    var remoteUrl: URL { get }
    
    /// The item's current state.
    var state: DTGItemState { get }
    
    /// Estimated size of the item.
    var estimatedSize: Int64? { get }
    
    /// Downloaded size in bytes.
    var downloadedSize: Int64 { get }
}

/// Information about a Video track.
public protocol DTGVideoTrack {
    /// Width in pixels.
    var width: Int? { get }
    
    /// Height in pixels.
    var height: Int? { get }
    
    /// Bitrate.
    var bitrate: Int { get }
}

/// Item state.
public enum DTGItemState: Int {
    /// Item was just added, no metadata is available except for the id and the URL.
    case new
    
    /// Item's metadata was loaded. Tracks information is available.
    case metadataLoaded
    
    /// Item download is in progress.
    case inProgress
    
    /// Item is paused by the app/user.
    case paused
    
    /// Item has finished downloading and processing.
    case completed
    
    /// Item download has failed.
    case failed
    
    /// Item is removed. This is only a temporary state, as the item is actually removed.
    case removed
    
    init?(value: String) {
        switch value {
        case DTGItemState.new.asString(): self = .new
        case DTGItemState.metadataLoaded.asString(): self = .metadataLoaded
        case DTGItemState.inProgress.asString(): self = .inProgress
        case DTGItemState.paused.asString(): self = .paused
        case DTGItemState.completed.asString(): self = .completed
        case DTGItemState.failed.asString(): self = .failed
        case DTGItemState.removed.asString(): self = .removed
        default: return nil
        }
    }
    
    public func asString() -> String {
        switch self {
        case .new: return "new"
        case .metadataLoaded: return "metadataLoaded"
        case .inProgress: return "inProgress"
        case .paused: return "paused"
        case .completed: return "completed"
        case .failed: return "failed"
        case .removed: return "removed"
        }
    }
}
