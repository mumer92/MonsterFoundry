import PencilKit
import SwiftUI
import UIKit

struct DrawingScreen: View {
    @Binding var drawing: PKDrawing
    @Binding var inputMode: CreationInputMode
    @Binding var creaturePrompt: String
    @Binding var tool: DrawingTool
    @Binding var inkColor: Color
    @Binding var selectedColorName: String
    @Binding var palette: DrawingPalette
    @Binding var brushWidth: Double
    @Binding var brushOpacity: Double
    @Binding var canvasCommand: CanvasCommand?
    let onNext: () -> Void
    let onOpenGallery: () -> Void

    @State private var confirmsClear = false

    var body: some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height * 1.12

            VStack(spacing: 12) {
                studioHeader
                sourcePicker

                if landscape {
                    HStack(alignment: .top, spacing: 14) {
                        sourceSurface(height: max(proxy.size.height - 154, 430))
                            .frame(maxWidth: .infinity)

                        ScrollView {
                            VStack(spacing: 12) {
                                if inputMode == .draw { brushStudio }
                                actionFooter
                            }
                        }
                        .scrollIndicators(.hidden)
                        .frame(width: min(max(proxy.size.width * 0.32, proxy.size.width > 900 ? 390 : 300), 460))
                    }
                    .padding(14)
                    .monsterGlassPanel()
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        drawingStudio(canvasHeight: preferredCanvasHeight(for: proxy.size))
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(maxWidth: 1_420, maxHeight: .infinity)
            .padding(.horizontal, proxy.size.width > 650 ? 24 : 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
        }
        .confirmationDialog("Clear this drawing?", isPresented: $confirmsClear, titleVisibility: .visible) {
            Button("Clear Canvas", role: .destructive) { drawing = PKDrawing() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every stroke so you can start a new idea.")
        }
    }

    private var studioHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            brandAndPrompt
            Spacer(minLength: 10)
            ViewThatFits(in: .horizontal) {
                judgePath
                EmptyView()
            }
            Button(action: onOpenGallery) {
                Label("My Creations", systemImage: "rectangle.stack.fill")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .padding(.horizontal, 13)
                    .frame(minHeight: 42)
                    .background(.white.opacity(0.09), in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityIdentifier("openGalleryButton")
        }
        .padding(.horizontal, 4)
    }

    private var brandAndPrompt: some View {
        HStack(spacing: 14) {
            Image(systemName: "wand.and.stars.inverse")
                .font(.title2.weight(.black))
                .foregroundStyle(MonsterTheme.ink)
                .frame(width: 50, height: 50)
                .background(MonsterTheme.mango, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("MONSTER FOUNDRY")
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.56))
                Text(inputMode == .draw ? "Draw something **impossible.**" : "Describe something **impossible.**")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
            }
        }
    }

    private var judgePath: some View {
        HStack(spacing: 8) {
            JudgeStep(number: "1", text: "Draw")
            Image(systemName: "arrow.right").foregroundStyle(.white.opacity(0.28))
            JudgeStep(number: "2", text: "Direct")
            Image(systemName: "arrow.right").foregroundStyle(.white.opacity(0.28))
            JudgeStep(number: "3", text: "Play")
        }
    }

    private var sourcePicker: some View {
        HStack(spacing: 7) {
            ForEach(CreationInputMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                        inputMode = mode
                    }
                } label: {
                    Label(mode.title, systemImage: mode.symbol)
                        .font(.system(.subheadline, design: .rounded, weight: .black))
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .foregroundStyle(inputMode == mode ? MonsterTheme.ink : .white.opacity(0.70))
                        .background(inputMode == mode ? MonsterTheme.mango : .white.opacity(0.07), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(inputMode == mode ? .isSelected : [])
            }
        }
        .padding(5)
        .background(.black.opacity(0.18), in: Capsule())
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func drawingStudio(canvasHeight: CGFloat) -> some View {
        VStack(spacing: 12) {
            sourceSurface(height: canvasHeight)
            if inputMode == .draw { brushStudio }
            actionFooter
        }
        .padding(14)
        .monsterGlassPanel()
    }

    @ViewBuilder
    private func sourceSurface(height: CGFloat) -> some View {
        if inputMode == .draw {
            canvas(height: height)
        } else {
            promptPad(height: height)
        }
    }

    private func canvas(height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(MonsterTheme.paper)

            DotPaper()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            PencilCanvas(
                drawing: $drawing,
                tool: tool,
                color: UIColor(inkColor),
                width: brushWidth,
                opacity: brushOpacity,
                command: canvasCommand
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            if drawing.strokes.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "scribble.variable")
                        .font(.system(size: 48, weight: .bold))
                    Text("Your idea starts here")
                        .font(.system(.title3, design: .rounded, weight: .black))
                    Text("Try a body, an eye, and one wonderfully strange feature.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(MonsterTheme.deepPurple.opacity(0.38))
                .allowsHitTesting(false)
            }

            Label("LIVE CANVAS", systemImage: "applepencil.and.scribble")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(MonsterTheme.deepPurple.opacity(0.45))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.65), in: Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(14)
                .allowsHitTesting(false)

            if !drawing.strokes.isEmpty {
                Text("\(drawing.strokes.count) stroke\(drawing.strokes.count == 1 ? "" : "s")")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(MonsterTheme.deepPurple.opacity(0.45))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.62), in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.34), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.26), radius: 18, y: 9)
        .accessibilityIdentifier("drawingCanvas")
    }

    private func promptPad(height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(MonsterTheme.paper)

            TextEditor(text: $creaturePrompt)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(MonsterTheme.deepPurple)
                .scrollContentBackground(.hidden)
                .padding(24)
                .accessibilityIdentifier("creaturePromptEditor")

            if creaturePrompt.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 42, weight: .bold))
                    Text("Describe something impossible…")
                        .font(.system(.title2, design: .rounded, weight: .black))
                    Text("Example: A shy triangle bus with six tiny boots that sneezes bubbles when it gets excited.")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .frame(maxWidth: 560, alignment: .leading)
                }
                .foregroundStyle(MonsterTheme.deepPurple.opacity(0.36))
                .padding(34)
                .allowsHitTesting(false)
            }

            Label("CREATIVE PROMPT", systemImage: "wand.and.stars")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(MonsterTheme.deepPurple.opacity(0.46))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.68), in: Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(14)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.34), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.26), radius: 18, y: 9)
    }

    private var brushStudio: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text("BRUSH STUDIO")
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.50))

                Capsule()
                    .fill(tool == .eraser ? Color.white.opacity(0.45) : inkColor.opacity(brushOpacity))
                    .frame(width: 56, height: max(2, min(CGFloat(brushWidth) * 0.32, 12)))

                Text(tool.title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(MonsterTheme.mango)
                Spacer()
                Text("Pencil + finger")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.38))
            }

            ScrollView(.horizontal) {
                HStack(spacing: 7) {
                    ForEach(DrawingTool.allCases) { choice in
                        BrushToolButton(tool: choice, selected: tool == choice) {
                            selectTool(choice)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
            .scrollIndicators(.hidden)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    colorPalette
                    Divider().frame(height: 42).overlay(.white.opacity(0.16))
                    brushSliders
                    Divider().frame(height: 42).overlay(.white.opacity(0.16))
                    canvasActions
                }

                VStack(spacing: 10) {
                    colorPalette
                    HStack(spacing: 12) {
                        brushSliders
                        canvasActions
                    }
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var colorPalette: some View {
        HStack(spacing: 7) {
            Menu {
                ForEach(DrawingPalette.allCases) { choice in
                    Button(choice.title, systemImage: choice.symbol) {
                        palette = choice
                    }
                }
            } label: {
                Image(systemName: palette.symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MonsterTheme.mango)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .accessibilityLabel("Colour palette, \(palette.title)")

            ScrollView(.horizontal) {
                HStack(spacing: 7) {
                    ForEach(palette.swatches) { swatch in
                        Button {
                            inkColor = swatch.color
                            selectedColorName = swatch.name
                            if tool == .eraser { selectTool(.ink) }
                        } label: {
                            Circle()
                                .fill(swatch.color)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Circle().stroke(.white, lineWidth: selectedColorName == swatch.name ? 3 : 0)
                                }
                                .padding(2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(swatch.name) colour")
                        .accessibilityAddTraits(selectedColorName == swatch.name ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)

            ColorPicker("Custom colour", selection: customColorBinding, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 38, height: 38)
                .accessibilityIdentifier("customColorPicker")
        }
        .frame(maxWidth: 430)
    }

    private var customColorBinding: Binding<Color> {
        Binding(
            get: { inkColor },
            set: {
                inkColor = $0
                selectedColorName = "Custom"
                if tool == .eraser { selectTool(.ink) }
            }
        )
    }

    private var brushSliders: some View {
        HStack(spacing: 12) {
            LabeledBrushSlider(
                title: "SIZE",
                valueText: "\(Int(brushWidth.rounded()))",
                value: $brushWidth,
                range: tool.widthRange
            )

            if tool != .eraser {
                LabeledBrushSlider(
                    title: "FLOW",
                    valueText: "\(Int((brushOpacity * 100).rounded()))%",
                    value: $brushOpacity,
                    range: 0.1...1
                )
            }
        }
    }

    private var canvasActions: some View {
        HStack(spacing: 6) {
            StudioActionButton(symbol: "arrow.uturn.backward", label: "Undo") {
                canvasCommand = CanvasCommand(kind: .undo)
            }
            StudioActionButton(symbol: "arrow.uturn.forward", label: "Redo") {
                canvasCommand = CanvasCommand(kind: .redo)
            }
            StudioActionButton(symbol: "trash", label: "Clear", destructive: true) {
                confirmsClear = true
            }
        }
    }

    private var actionFooter: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 18) {
                drawingTip
                Spacer()
                awakenButton.frame(maxWidth: 380)
            }
            VStack(spacing: 10) {
                drawingTip
                awakenButton
            }
        }
    }

    private var drawingTip: some View {
        Label(
            inputMode == .draw
                ? "One big character or object works best—roughness makes it funnier."
                : "A shape, personality, and one odd detail is plenty.",
            systemImage: "lightbulb.fill"
        )
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(MonsterTheme.mint)
    }

    private var awakenButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text(canContinue ? "NEXT: DIRECT THE MAGIC" : emptyActionTitle)
                Image(systemName: "arrow.up.right")
            }
        }
        .buttonStyle(PrimaryMonsterButtonStyle())
        .disabled(!canContinue)
        .opacity(canContinue ? 1 : 0.46)
        .accessibilityIdentifier("bringItAliveButton")
        .accessibilityHint("Opens the art style and story direction choices")
    }

    private var canContinue: Bool {
        switch inputMode {
        case .draw: !drawing.strokes.isEmpty
        case .prompt: creaturePrompt.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
        }
    }

    private var emptyActionTitle: String {
        inputMode == .draw ? "DRAW SOMETHING FIRST" : "DESCRIBE SOMETHING FIRST"
    }

    private func selectTool(_ selectedTool: DrawingTool) {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
            tool = selectedTool
            brushWidth = selectedTool.defaultWidth
            brushOpacity = selectedTool.defaultOpacity
        }
    }

    private func preferredCanvasHeight(for size: CGSize) -> CGFloat {
        if size.width >= 700 {
            return min(max(size.height * 0.58, size.width * 0.70), 900)
        }
        return min(max(size.height * 0.43, size.width * 0.90), 520)
    }
}

struct JudgeStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Text(number)
                .font(.system(.caption2, design: .rounded, weight: .black))
                .frame(width: 20, height: 20)
                .foregroundStyle(MonsterTheme.ink)
                .background(MonsterTheme.mango, in: Circle())
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }
}

private struct BrushToolButton: View {
    let tool: DrawingTool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tool.symbol)
                    .font(.system(size: 17, weight: .bold))
                Text(tool.title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(selected ? MonsterTheme.ink : .white.opacity(0.76))
            .frame(width: 82, height: 54)
            .background(selected ? MonsterTheme.mango : .white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tool.title) tool")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct LabeledBrushSlider: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(0.8)
                Spacer()
                Text(valueText)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(.white.opacity(0.52))
            Slider(value: $value, in: range)
                .tint(MonsterTheme.mango)
        }
        .frame(width: 116)
        .accessibilityLabel(title.capitalized)
        .accessibilityValue(valueText)
    }
}

private struct StudioActionButton: View {
    let symbol: String
    let label: String
    var destructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(destructive ? MonsterTheme.pink : .white.opacity(0.78))
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.07), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct DotPaper: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 28
            for x in stride(from: spacing, to: size.width, by: spacing) {
                for y in stride(from: spacing, to: size.height, by: spacing) {
                    let rect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                    context.fill(Path(ellipseIn: rect), with: .color(MonsterTheme.deepPurple.opacity(0.09)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
