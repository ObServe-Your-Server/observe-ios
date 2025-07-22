import SwiftUI

struct DotProgressView: View {
    @State private var y: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Dot(y: y)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(0), value: y)
                    Dot(y: y)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.2), value: y)
                    Dot(y: y)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.4), value: y)
                }
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear { y = -8 }
        }
    }
}

struct Dot: View {
    var y : CGFloat
    
    var body: some View {
        Circle()
            .frame(width: 8, height: 8, alignment: .center)
            .opacity(y == 0 ? 0.1 : 1)
            .offset(y: y)
            .foregroundColor(Color("Blue"))
    }
}

struct DotProgressView_Previews: PreviewProvider {
    static var previews: some View {
        DotProgressView()
    }
}
