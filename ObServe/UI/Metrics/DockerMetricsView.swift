import SwiftUI

struct DockerMetricsView: View {
    @ObservedObject var dockerManager: DockerMetricsManager
    @State private var isExpanded: Bool = false

    private var runningCount: Int {
        dockerManager.containers.filter { $0.running == true }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 12)

                // Collapsed summary — only visible when collapsed
                if !isExpanded { HStack(spacing: 18) {
                    HStack {
                        Text("RUNNING")
                            .foregroundColor(Color.gray)
                            .font(.plexSans(size: 10, weight: .medium))
                        Spacer()
                        Text("\(runningCount)")
                            .foregroundColor(.white)
                            .font(.plexSans(size: 18, weight: .bold))
                    }
                    HStack {
                        Text("ONLINE")
                            .foregroundColor(Color.gray)
                            .font(.plexSans(size: 10, weight: .medium))
                        Spacer()
                        Text("\(runningCount)")
                            .foregroundColor(.white)
                            .font(.plexSans(size: 18, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isExpanded {
                    // TOTAL gray-box header row
                    HStack {
                        Text("TOTAL")
                            .foregroundColor(Color.gray)
                            .font(.plexSans(size: 12, weight: .medium))
                        Spacer()
                        Text("\(dockerManager.containers.count)")
                            .foregroundColor(.white)
                            .font(.plexSans(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 0).fill(Color(red: 0.102, green: 0.102, blue: 0.102)))

                    if dockerManager.containers.isEmpty {
                        Text("No containers found")
                            .foregroundColor(Color.gray)
                            .font(.plexSans(size: 12, weight: .medium))
                            .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(dockerManager.containers.enumerated()), id: \.offset) { index, container in
                                HStack(spacing: 0) {
                                    ContainerBox(number: index + 1)
                                        .frame(width: 52, alignment: .leading)
                                    Text(container.hostName ?? container.containerId ?? "—")
                                        .foregroundColor(.white)
                                        .font(.plexSans(size: 15, weight: .medium))
                                        .lineLimit(1)
                                    Spacer()
                                    StatusCircle(isRunning: container.running == true)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                Text("CONTAINERS")
                    .foregroundColor(.white)
                    .font(.plexSans(size: 14, weight: .medium))
                    .padding(10)
                    .background(Color.black)
                    .padding(.top, -18)
                    .padding(.leading, 10)
            }
            .overlay(alignment: .bottomTrailing) {
                ExpandCornerIndicator()
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - 3D Box shape for container numbering

private struct ContainerBox: View {
    let number: Int

    private let frontW: CGFloat = 31
    private let frontH: CGFloat = 18
    private let topH: CGFloat = 8

    var body: some View {
        Canvas { ctx, _ in
            let stroke = Color(red: 0x41 / 255, green: 0x41 / 255, blue: 0x41 / 255)
            let fill = stroke.opacity(0.25)

            // Top face — trapezoid converging to center for perspective
            let slant: CGFloat = 6
            var top = Path()
            top.move(to: CGPoint(x: slant, y: 0))
            top.addLine(to: CGPoint(x: frontW - slant, y: 0))
            top.addLine(to: CGPoint(x: frontW, y: topH))
            top.addLine(to: CGPoint(x: 0, y: topH))
            top.closeSubpath()
            ctx.fill(top, with: .color(fill))
            ctx.stroke(top, with: .color(stroke), lineWidth: 1.5)

            // Front face
            let front = CGRect(x: 0, y: topH, width: frontW, height: frontH)
            ctx.fill(Path(front), with: .color(fill))
            ctx.stroke(Path(front), with: .color(stroke), lineWidth: 1.5)
        }
        .frame(width: frontW, height: frontH + topH)
        .overlay(
            Text("\(number)")
                .foregroundColor(.white)
                .font(.plexSans(size: 16, weight: .medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(red: 0x0F / 255, green: 0x0F / 255, blue: 0x0F / 255))
                .offset(y: topH - 7)
        )
    }
}

// MARK: - Status circle

private struct StatusCircle: View {
    let isRunning: Bool

    var body: some View {
        Circle()
            .fill(isRunning ? Color(red: 0.2, green: 0.78, blue: 0.35) : Color.gray)
            .frame(width: 10, height: 10)
    }
}
