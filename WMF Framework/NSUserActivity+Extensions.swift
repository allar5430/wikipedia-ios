import Foundation
import CoreLocation

public extension NSUserActivity {
    @objc var shouldSkipOnboarding: Bool {
        guard let path = webpageURL?.wikiResourcePath,
              let languageCode = webpageURL?.wmf_languageCode else {
            return false
        }

        let namespaceAndTitle = path.namespaceAndTitleOfWikiResourcePath(with: languageCode)
        let namespace = namespaceAndTitle.0
        let title = namespaceAndTitle.1

        return namespace == .special && title == "ReadingLists"
    }

    var validPlacesCoordinate: CLLocationCoordinate2D? {
        guard let location = userInfo?["WMFLocation"] as? [String: Any],
              let latitude = (location["lat"] as? NSNumber)?.doubleValue,
              let longitude = (location["long"] as? NSNumber)?.doubleValue else {
            return nil
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            return nil
        }

        return coordinate
    }
}

@objc(WMFPlacesActivityBuilder)
public final class PlacesActivityBuilder: NSObject {
    @objc(activityFromURL:)
    public static func activity(from url: URL) -> NSUserActivity {
        let activity = pageActivity(named: "Places")
        activity.webpageURL = articleURL(from: url)

        if let locationDictionary = locationDictionary(from: url) {
            var userInfo = activity.userInfo ?? [:]
            userInfo["WMFLocation"] = locationDictionary
            activity.userInfo = userInfo
        }

        return activity
    }

    private static func pageActivity(named pageName: String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "org.wikimedia.wikipedia.\(pageName.lowercased())")
        activity.eligibleForHandoff = true
        activity.eligibleForSearch = true
        activity.eligibleForPublicIndexing = true
        activity.title = pageName
        activity.userInfo = ["WMFPage": pageName]

        var keywords = Set(["Wikipedia", "Wikimedia", "Wiki"])
        keywords.formUnion(pageName.components(separatedBy: " "))
        activity.keywords = keywords

        return activity
    }

    private static func articleURL(from url: URL) -> URL? {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let articleURLString = queryItems.first(where: { $0.name == "WMFArticleURL" })?.value else {
            return nil
        }

        return URL(string: articleURLString)
    }

    private static func locationDictionary(from url: URL) -> NSDictionary? {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let latitudeString = queryItems.first(where: { $0.name == "lat" })?.value,
              let longitudeString = queryItems.first(where: { $0.name == "long" })?.value else {
            return nil
        }

        let latitude = (latitudeString as NSString).doubleValue
        let longitude = (longitudeString as NSString).doubleValue
        return ["lat": NSNumber(value: latitude), "long": NSNumber(value: longitude)]
    }
}
