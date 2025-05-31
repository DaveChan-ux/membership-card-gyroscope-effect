import SwiftUI
import UIKit

struct MemberCard: View {
    @State private var isPressed: Bool = false
    @State private var isDragging: Bool = false
    @State private var lightPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @State private var rotation: CGPoint = CGPoint(x: 0, y: 0)
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var dragShimmerPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)

    // Computed properties for gradients
    private var holographicGradient: LinearGradient {
        LinearGradient(
            colors: [Color.clear, Color.white.opacity(0.05), Color.clear],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [Color.clear, Color.white.opacity(0.2), Color.clear],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var glassGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.25),
                Color.white.opacity(0.15),
                Color.white.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shimmerMask: LinearGradient {
        if isDragging {
            // Use drag position for shimmer when dragging
            let centerX = dragShimmerPosition.x
            let centerY = dragShimmerPosition.y
            return LinearGradient(
                colors: [Color.clear, Color.white, Color.clear],
                startPoint: UnitPoint(x: centerX - 0.2, y: centerY - 0.2),
                endPoint: UnitPoint(x: centerX + 0.2, y: centerY + 0.2)
            )
        } else {
            // Use automatic diagonal shimmer when not dragging - starts further left
            return LinearGradient(
                colors: [Color.clear, Color.white, Color.clear],
                startPoint: UnitPoint(x: shimmerOffset - 0.15, y: (shimmerOffset - 0.3) * 0.5),
                endPoint: UnitPoint(x: shimmerOffset + 0.25, y: (shimmerOffset + 0.3) * 0.5)
            )
        }
    }

    // Light leak effect - new addition
    private var lightLeakEffect: some View {
        ZStack {
            // Main radial light burst - white to yellow
            RadialGradient(
                colors: [
                    Color.white.opacity(isPressed ? 0.9 : 0.0),
                    Color.yellow.opacity(isPressed ? 0.7 : 0.0),
                    Color.orange.opacity(isPressed ? 0.4 : 0.0),
                    Color.clear
                ],
                center: UnitPoint(x: lightPosition.x, y: lightPosition.y),
                startRadius: 0,
                endRadius: isPressed ? 250 : 60
            )

            // Secondary softer glow - warm tones
            RadialGradient(
                colors: [
                    Color.white.opacity(isPressed ? 0.6 : 0.0),
                    Color.yellow.opacity(isPressed ? 0.4 : 0.0),
                    Color.orange.opacity(isPressed ? 0.2 : 0.0),
                    Color.clear
                ],
                center: UnitPoint(x: lightPosition.x, y: lightPosition.y),
                startRadius: 0,
                endRadius: isPressed ? 400 : 100
            )

            // Outer atmospheric glow - subtle warm ambiance
            RadialGradient(
                colors: [
                    Color.yellow.opacity(isPressed ? 0.2 : 0.0),
                    Color.orange.opacity(isPressed ? 0.1 : 0.0),
                    Color.clear
                ],
                center: UnitPoint(x: lightPosition.x, y: lightPosition.y),
                startRadius: 100,
                endRadius: isPressed ? 600 : 150
            )
        }
        .scaleEffect(isPressed ? 1.4 : 0.8)
        .opacity(isPressed ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.4), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: lightPosition)
        .blendMode(.screen)
        .offset(y: 8) // Offset slightly to appear behind the card
        .mask(featheredCardMask)
    }

    // Feathered mask that matches card shape with soft edges
    private var featheredCardMask: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white)
            .frame(height: 224)
            .scaleEffect(1.1) // Slightly larger to ensure coverage
            .blur(radius: 10) // Creates the feathered edge
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Light leak effect behind everything - with feathered card mask
                lightLeakEffect
                    .frame(height: 244) // Slightly larger than card for feathering
                    .blur(radius: 8)

                cardContent
                    .frame(height: 224)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(borderOverlay)
                    .background(glowEffect)
                    .scaleEffect(isPressed ? 1.05 : 1.0)
                    .rotation3DEffect(
                        .degrees(rotation.x),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
                    .rotation3DEffect(
                        .degrees(rotation.y),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .animation(.easeOut(duration: 0.3), value: rotation)
                    .animation(.easeOut(duration: 0.3), value: isPressed)
                    .gesture(cardGesture(geometry: geometry))
                    .onAppear {
                        // Start the automatic shimmer animation further left
                        shimmerOffset = -1.5
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                            shimmerOffset = 1.8
                        }
                    }
            }
        }
        .frame(height: 224)
    }

    // MARK: - Card Content
    private var cardContent: some View {
        ZStack {
            baseCard
            holographicOverlay
            glassOverlay
            shimmerEffect
            contentLayer
        }
    }

    private var baseCard: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(
                Color.black.opacity(0.3)
            )
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemGray6).opacity(0.1))
                    .blur(radius: 0.5)
            )
    }

    private var holographicOverlay: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(holographicGradient)
            .opacity(0.3)
    }

    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(glassGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }

    private var shimmerEffect: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(shimmerGradient)
            .mask(
                RoundedRectangle(cornerRadius: 24)
                    .fill(shimmerMask)
            )
            .animation(
                isDragging ? .easeOut(duration: 2.0) : .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                value: isDragging ? dragShimmerPosition.x : shimmerOffset
            )
    }

    private var contentLayer: some View {
        VStack(spacing: 0) {
            headerSection
            Spacer()
            bottomSection
        }
        .padding(24)
    }

    // MARK: - Content Sections
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MakerTodd")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("1.5M Followers")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            starRating
        }
    }

    private var starRating: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 16) {
            memberIdSection
            bottomRow
        }
    }

    private var memberIdSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Member ID")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }

            HStack {
                Text("**** **** **** 1234")
                    .font(.title3)
                    .foregroundColor(.white)
                    .tracking(2)
                Spacer()
            }
        }
    }

    private var bottomRow: some View {
        HStack {
            validThruSection
            Spacer()
            levelSection
        }
    }

    private var validThruSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Valid Thru")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))

            Text("12/27")
                .font(.caption)
                .foregroundColor(.white)
        }
    }

    private var levelSection: some View {
        HStack(spacing: 8) {
            sparkleIcon

            VStack(alignment: .trailing, spacing: 2) {
                Text("Level")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))

                Text("PLATINUM")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }

    private var sparkleIcon: some View {
        Image(systemName: "sparkles")
            .foregroundColor(.white.opacity(0.8))
            .font(.title3)
            .opacity(isPressed ? 1.0 : 0.7)
            .animation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true),
                value: isPressed
            )
    }

    // MARK: - Border and Effects
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 24)
            .stroke(
                Color.white.opacity(isPressed ? 0.8 : 0.4),
                lineWidth: 1
            )
            .animation(.easeInOut(duration: 0.3), value: isPressed)
    }

    private var glowEffect: some View {
        ZStack {
            // Outer glow - largest radius
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.clear)
                .shadow(
                    color: Color.cyan.opacity(isPressed ? 0.4 : 0.2),
                    radius: isPressed ? 30 : 20,
                    x: 0,
                    y: 0
                )

            // Mid glow - medium radius
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.clear)
                .shadow(
                    color: Color.blue.opacity(isPressed ? 0.3 : 0.15),
                    radius: isPressed ? 20 : 12,
                    x: 0,
                    y: 0
                )

            // Inner glow - smallest radius
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.clear)
                .shadow(
                    color: Color.white.opacity(isPressed ? 0.6 : 0.3),
                    radius: isPressed ? 10 : 6,
                    x: 0,
                    y: 0
                )
        }
        .animation(.easeInOut(duration: 0.3), value: isPressed)
    }

    // MARK: - Gesture Handling
    private func cardGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleInteraction(
                    location: value.location,
                    geometry: geometry,
                    isActive: true
                )
            }
            .onEnded { _ in
                handleInteractionEnd()
            }
    }

    private func handleInteraction(location: CGPoint, geometry: GeometryProxy, isActive: Bool) {
        let size = geometry.size
        let x = location.x / size.width
        let y = location.y / size.height

        // Add haptic feedback when starting to press
        if isActive && !isPressed {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }

        // Calculate 3D rotation based on position
        let rotateY = ((x - 0.5) / 0.5) * 15 // Max 15 degrees rotation on Y axis
        let rotateX = -((y - 0.5) / 0.5) * 15 // Max 15 degrees rotation on X axis (inverted)

        lightPosition = CGPoint(x: x, y: y)
        dragShimmerPosition = CGPoint(x: x, y: y)
        rotation = CGPoint(x: rotateX, y: rotateY)
        isPressed = isActive
        isDragging = isActive
    }

    private func handleInteractionEnd() {
        // Add haptic feedback when releasing
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        isPressed = false
        isDragging = false
        rotation = CGPoint(x: 0, y: 0)

        // Restart automatic shimmer animation from the left
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shimmerOffset = -1.5
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.8
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                MemberCard()
                    .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
