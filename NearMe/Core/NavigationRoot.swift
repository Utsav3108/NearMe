import SwiftUI

struct NavigationRoot: View {
    @Environment(AppRouter.self) private var appRouter

    var body: some View {
        Group {
            if appRouter.isAuthenticated {
                MainTabView()
            } else if appRouter.showsSignIn {
                SignInView()
            } else {
                GettingStarted(
                    onGetStarted: appRouter.showSignIn,
                    onSignIn: appRouter.showSignIn
                )
            }
        }
        .animation(.easeInOut, value: appRouter.isAuthenticated)
        .animation(.easeInOut, value: appRouter.showsSignIn)
    }
}

struct MainTabView: View {
    @Environment(AppRouter.self) private var appRouter

    var body: some View {
        @Bindable var appRouter = appRouter

        TabView(selection: $appRouter.selectedTab) {
            tabNavigation(for: .home) {
                Home()
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.systemImage)
            }
            .tag(AppTab.home)

            tabNavigation(for: .explore) {
                TabPlaceholderView(tab: .explore)
            }
            .tabItem {
                Label(AppTab.explore.title, systemImage: AppTab.explore.systemImage)
            }
            .tag(AppTab.explore)

            tabNavigation(for: .create) {
                TabPlaceholderView(tab: .create)
            }
            .tabItem {
                Label(AppTab.create.title, systemImage: AppTab.create.systemImage)
            }
            .tag(AppTab.create)

            tabNavigation(for: .saved) {
                TabPlaceholderView(tab: .saved)
            }
            .tabItem {
                Label(AppTab.saved.title, systemImage: AppTab.saved.systemImage)
            }
            .tag(AppTab.saved)

            tabNavigation(for: .profile) {
                ProfileTabView()
            }
            .tabItem {
                Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage)
            }
            .tag(AppTab.profile)
        }
    }

    private func tabNavigation<Content: View>(
        for tab: AppTab,
        @ViewBuilder root: () -> Content
    ) -> some View {
        @Bindable var appRouter = appRouter
        let path = Binding(
            get: { appRouter.paths[tab, default: []] },
            set: { appRouter.paths[tab] = $0 }
        )

        return NavigationStack(path: path) {
            root()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        Home()
                    }
                }
        }
    }
}

private struct SignInView: View {
    @Environment(AppRouter.self) private var appRouter

    @State private var emailAddress = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "person.crop.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)

                Text("Welcome back")
                    .font(.largeTitle.bold())

                Text("Sign in to save places and personalize your recommendations.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                TextField("Email address", text: $emailAddress)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button("Sign in") {
                    appRouter.completeAuthentication()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .frame(maxWidth: .infinity)

                Button("Back") {
                    appRouter.showOnboarding()
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(24)
            .navigationBarBackButtonHidden()
        }
    }
}

private struct TabPlaceholderView: View {
    let tab: AppTab

    var body: some View {
        ContentUnavailableView(
            tab.title,
            systemImage: tab.systemImage,
            description: Text("\(tab.title) is ready for its feature content.")
        )
        .navigationTitle(tab.title)
    }
}

private struct ProfileTabView: View {
    @Environment(AppRouter.self) private var appRouter

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("Profile")
                .font(.title.bold())

            Button("Sign out", role: .destructive) {
                appRouter.signOut()
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle(AppTab.profile.title)
    }
}
