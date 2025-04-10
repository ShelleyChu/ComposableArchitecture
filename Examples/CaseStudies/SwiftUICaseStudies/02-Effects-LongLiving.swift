import Combine
import ComposableArchitecture
import SwiftUI

private let readMe = """
  This application demonstrates how to handle long-living effects, for example notifications from \
  Notification Center.

  Run this application in the simulator, and take a few screenshots by going to \
  *Device › Screenshot* in the menu, and observe that the UI counts the number of times that \
  happens.

  Then, navigate to another screen and take screenshots there, and observe that this screen does \
  *not* count those screenshots.
  """

// MARK: - Application domain

struct LongLivingEffectsState: Equatable {
  var screenshotCount = 0
}

enum LongLivingEffectsAction {
  case userDidTakeScreenshotNotification
  case onAppear
  case onDisappear
}

struct LongLivingEffectsEnvironment {
  var notificationCenter: NotificationCenter
}

// MARK: - Business logic

let longLivingEffectsReducer = Reducer<
  LongLivingEffectsState, LongLivingEffectsAction, LongLivingEffectsEnvironment
> { state, action, environment in

  enum UserDidTakeScreenshotNotificationId {}

  switch action {
  case .userDidTakeScreenshotNotification:
    state.screenshotCount += 1
    return .none

  case .onAppear:
    // When the view appears, start the effect that emits when screenshots are taken.
    return environment.notificationCenter
      .publisher(for: UIApplication.userDidTakeScreenshotNotification)
      .eraseToEffect { _ in LongLivingEffectsAction.userDidTakeScreenshotNotification }
      .cancellable(id: UserDidTakeScreenshotNotificationId.self)

  case .onDisappear:
    // When view disappears, stop the effect.
    return .cancel(id: UserDidTakeScreenshotNotificationId.self)
  }
}

// MARK: - SwiftUI view

struct LongLivingEffectsView: View {
  let store: Store<LongLivingEffectsState, LongLivingEffectsAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      Form {
        Section(header: Text(template: readMe, .body)) {
          Text("A screenshot of this screen has been taken \(viewStore.screenshotCount) times.")
            .font(.headline)
        }

        Section {
          NavigationLink(destination: self.detailView) {
            Text("Navigate to another screen")
          }
        }
      }
      .navigationBarTitle("Long-living effects")
      .onAppear { viewStore.send(.onAppear) }
      .onDisappear { viewStore.send(.onDisappear) }
    }
  }

  var detailView: some View {
    Text(
      """
      Take a screenshot of this screen a few times, and then go back to the previous screen to see \
      that those screenshots were not counted.
      """
    )
    .padding(.horizontal, 64)
  }
}

// MARK: - SwiftUI previews

struct EffectsLongLiving_Previews: PreviewProvider {
  static var previews: some View {
    let appView = LongLivingEffectsView(
      store: Store(
        initialState: LongLivingEffectsState(),
        reducer: longLivingEffectsReducer,
        environment: LongLivingEffectsEnvironment(
          notificationCenter: .default
        )
      )
    )

    return Group {
      NavigationView { appView }
      NavigationView { appView.detailView }
    }
  }
}
