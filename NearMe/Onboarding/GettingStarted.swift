import SwiftUI
import Playgrounds

struct GettingStarted: View {
    
    // MARK: - Environment
    @Environment(AppRouter.self) private var router
    
    // MARK: - Global Variable
    @State private var vm : GettingStartedVM = GettingStartedVM()
    
    
    // MARK: - View
    var body: some View {
        
        @Bindable var router = router
        
        ZStack {
            Image(.onboarding)
                .resizable()
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        VStack {
                            Text("Real places.")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                                .font(.system(size: 36))
                            
                            Text("Real stories.")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                                .font(.system(size: 36))
                        }
                        
                        Text("Discover & share amazing places around you.")
                            .foregroundStyle(.white)
                            .fontWeight(.regular)
                            .font(.system(size: 20))
                        
                        Spacer()
                    }
                    
                    .padding(.vertical, 50)
                    
                    Spacer()
                }
                
                Spacer()
                
                VStack {
                    Button {
                        print("Getting Started tapped")
                        vm.getStarted()
                    } label: {
                        Text("Get Started")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, maxHeight: 40)
                            .padding(.vertical, 10)
                            .background(.white, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(.black)
                        
                    }
                    
                    HStack {
                        Text("Already have an account?")
                            .foregroundStyle(.white)
                        
                        Button {
                            print("Signed In")
                            vm.navigateToSignIn()
                            router.push(.home)
                            
                        } label: {
                            Text("Sign in").foregroundStyle(.yellow)
                            
                        }
                    
                        
                    }
                }
            }
            .padding(.horizontal, 20)

            
            
        }
        
        
    }
}

#Preview {
    GettingStarted()
}
