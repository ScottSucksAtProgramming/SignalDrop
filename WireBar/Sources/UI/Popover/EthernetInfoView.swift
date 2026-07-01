import SwiftUI

struct EthernetInfoView: View {
    @ObservedObject var networkMonitor: NetworkMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "cable.connector.horizontal")
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text(String(localized: "Ethernet"))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if networkMonitor.state.primaryInterface?.hasPrefix("en") == true &&
                   networkMonitor.state.connectionType == .ethernet {
                    Text(String(localized: "Primary"))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15))
                        .clipShape(Capsule())
                        .accessibilityLabel(String(localized: "Primary network route"))
                }
            }

            if let ip = networkMonitor.state.ethernetIPAddress {
                DetailRow(
                    label: String(localized: "IP Address"),
                    value: ip,
                    copyable: true
                )
            }

            if let gateway = networkMonitor.state.gatewayAddress {
                DetailRow(
                    label: String(localized: "Gateway"),
                    value: gateway
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Ethernet connection details"))
    }
}
