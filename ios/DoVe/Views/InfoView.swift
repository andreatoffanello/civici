import SwiftUI

struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("DoVe")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "C2452D"))

                    Text("Trova ogni civico di Venezia")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                // What is a nizioleto
                InfoSection(
                    title: "Cos'è un nizioleto?",
                    icon: "text.quote",
                    content: "I nizioleti sono i cartelli dipinti sui muri di Venezia che indicano strade, campi e direzioni. Il nome viene dal veneziano \"lenzuoletto\" — piccoli rettangoli bianchi con scritte nere che da secoli guidano chi cammina per la città."
                )

                // How Venice addressing works
                InfoSection(
                    title: "I numeri civici di Venezia",
                    icon: "number",
                    content: "A Venezia i numeri civici non seguono le strade come nel resto del mondo: seguono i sestieri. Ogni sestiere ha una propria numerazione progressiva che può arrivare a migliaia. Per questo, sapere che un indirizzo è \"Cannaregio 2345\" non dice nulla su dove si trovi fisicamente — a meno di non avere DoVe."
                )

                // How the app works
                InfoSection(
                    title: "Come funziona",
                    icon: "sparkles",
                    content: "Scegli un sestiere, digita il numero civico, e DoVe ti mostra la posizione esatta sulla mappa. Puoi aprire la navigazione in Apple Maps per raggiungerlo a piedi."
                )

                // Sestieri
                VStack(alignment: .leading, spacing: 12) {
                    Label("I sestieri", systemImage: "map")
                        .font(.headline)

                    GlassEffectContainer {
                        VStack(spacing: 0) {
                            ForEach(Sestiere.allCases) { sestiere in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(sestiere.color)
                                        .frame(width: 10, height: 10)

                                    Text(sestiere.name)
                                        .font(.body)

                                    Spacer()

                                    Text(sestiere.numberRange)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)

                                if sestiere != Sestiere.allCases.last {
                                    Divider()
                                        .padding(.leading, 38)
                                }
                            }
                        }
                        .glassEffect(
                            .regular,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                }

                // Credits
                VStack(alignment: .center, spacing: 8) {
                    Text("Fatto con cura a Venezia")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)

                    Text("v1.0")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("Info")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct InfoSection: View {
    let title: String
    let icon: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }
}
