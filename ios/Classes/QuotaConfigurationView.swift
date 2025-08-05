//
//  QuotaConfigurationView.swift
//  screen_time_api_ios
//
//  Created by Quota System Implementation
//

import SwiftUI
import FamilyControls

struct QuotaConfigurationView: View {
    @StateObject var model = FamilyControlModel.shared

    var body: some View {
        FamilyActivityPicker(
            selection: $model.selectionForQuotaConfiguration
        )
    }
}

struct QuotaConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        QuotaConfigurationView()
    }
}
