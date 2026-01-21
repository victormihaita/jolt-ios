import Foundation

public enum PRConstants {
    public enum API {
//        #if DEBUG
        public static let baseURL = "http://192.168.100.70:8080/api/v1"
        public static let graphQLURL = "http://192.168.100.70:8080/graphql"
        public static let webSocketURL = "ws://192.168.100.70:8080/graphql"
//        #else
//        public static let baseURL = "https://jolt-api-502163195111.europe-west1.run.app/api/v1"
//        public static let graphQLURL = "https://jolt-api-502163195111.europe-west1.run.app/graphql"
//        public static let webSocketURL = "wss://jolt-api-502163195111.europe-west1.run.app/graphql"
//        #endif
    }

    public enum Keychain {
        public static let serviceName = "com.vm.power.reminders"
        public static let accessTokenKey = "accessToken"
        public static let refreshTokenKey = "refreshToken"
        public static let userIdKey = "userId"
    }

    public enum AppGroup {
        public static let identifier = "group.com.vm.power.reminders"
    }

    public enum Notifications {
        public static let categoryReminder = "REMINDER"
        public static let actionSnooze5 = "SNOOZE_5"
        public static let actionSnooze15 = "SNOOZE_15"
        public static let actionSnoozeCustom = "SNOOZE_CUSTOM"
        public static let actionComplete = "COMPLETE"
    }

    public enum Snooze {
        public static let freePresets = [5, 15, 30, 60]
        public static let premiumPresets = [5, 10, 15, 20, 30, 45, 60, 120, 180, 1440]
    }

    public enum Premium {
        public static let maxFreeDevices = 2
        public static let entitlementID = "premium"
    }
}
