import SwiftUI

struct GettingStarted: View {
    let onGetStarted: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        ZStack {
            Image(.onboarding)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Real places.")
                            .foregroundStyle(.white)
                            .font(.largeTitle.bold())

                        Text("Real stories.")
                            .foregroundStyle(.white)
                            .font(.largeTitle.bold())

                        Text("Discover & share amazing places around you.")
                            .foregroundStyle(.white)
                            .font(.title3)
                    }
                    .padding(.top, 50)

                    Spacer()
                }

                Spacer()

                VStack(spacing: 16) {
                    Button(action: onGetStarted) {
                        Text("Get Started")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .foregroundStyle(.black)
                    }

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(.white)

                        Button("Sign in", action: onSignIn)
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }
}

#Preview {
    GettingStarted(onGetStarted: {}, onSignIn: {})
}
