//
//  WelcomeWizardView2.swift
//  Raincoat
//
//  Created by Maija Philip on 10/27/23.
//

import SwiftUI
import SwiftData
import AVFoundation
import PhotosUI
/**
 Second screen of the Wizard shown to a new user, their skin color is generated from an image they provide
 */
struct WelcomeWizardView2: View {
    
    /// change the image based on dark or light theme so the background matches the screen
    // @Environment(User.self) private var user: User
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode> // make the save button go back to the settings
    @Environment(\.modelContext) private var modelContext
    @Query private var user: [User]
    
    @State private var photo: UIImage? = nil
    
    // params
    @State var isWelcomeWizard: Bool
    @State var welcomeUser: WelcomeUser?
    @State var location: Location?
    
    // check if the permisions allow us to use camera, needs to be passed into Photo View
    func canWeUseCamera() -> Bool {
        
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            // print("already authorized")
            return true
        } else {
            var result = false
            
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    // print("They gave us permission!")
                    result = true
                } else {
                    // print("...they didn't give us permission")
                    result = false
                    
                } // if granted
            }) // request access
            
            return result
        } // if already authorized
        
    } // can we use camera
    
    var body: some View {
        NavigationStack {
            Color("Surface")
                .overlay(
                // Main Content
                    VStack {
                        // Title
                        Text("Customize your skin color")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color("OnSurface"))
                            .multilineTextAlignment(.center)
                            .padding()
                            .padding(.horizontal)
                        
                        // Subtitle / Instructions
                        Text("Click below to take an image of a patch of skin for your character")
                            .foregroundStyle(Color("OnSurface"))
                            .multilineTextAlignment(.center)
                            .padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
                        
                        Spacer()
                        
                        /// Image with background of the generated skin color or a grey template before they have selected
                        ImageWithSkinBehind(image: "skinPicker", welcomeUser: welcomeUser)
                            
                        
                        Spacer()
                        
                        
                        /// take image button, once first image is taken successfully, turns into less primary
                        PhotoView(photo: $photo, useCamera: canWeUseCamera())
                        
                        /// Continue once an image has been taken
                        if isWelcomeWizard && photo != nil {
                            Button {
                                if location != nil {
                                    welcomeUser?.location = location ?? Location()
                                }
                                modelContext.insert(User(welcomeUser: welcomeUser))
                            } label: {
                                SolidTextButton(text: "Continue", buttonLevel: .primary)
                            }
                        } else if photo != nil {
                            Button {
                                self.presentationMode.wrappedValue.dismiss()
                            } label: {
                                SolidTextButton(text: "Continue", buttonLevel: .primary)
                            }
                            
                        }
                        
                        /// skip for now and leave the skin grey option on welcome wizard
                        if isWelcomeWizard {
                            Button {
                                if location != nil {
                                    welcomeUser?.location = location ?? Location()
                                }
                                modelContext.insert(User(welcomeUser: welcomeUser))
                            } label: {
                                SolidTextButton(text: "Skip for now", buttonLevel: .tertiary)
                            }

                        }
                         
                        
                        
                    } // VStack stay in safe area
                    .padding()
                    .padding()
                    .padding(.top)
                    .padding(.top)
                    .navigationTitle("")
                    .onAppear() {
                        /// if a color exists, set it to the approriate user
                        if photo != nil {
                            let color = photo?.averageColor ?? .gray
                            
                            // if we have a user in the model, set that one, otherwise put it in the welcome user
                            if user.first != nil {
                                user[0].skincolor.set(color: color)
                            } else {
                                welcomeUser?.skincolor.set(color: color)
                            } // if first user exists
                            
                        }  // if photo exists
                    } // on Appear
            
            ) // main overlay
            .edgesIgnoringSafeArea(.vertical)
        } // Nagivation Stack
        .tint(Color("OnSurfaceVariant"))
            
    } // body
} // WelcomeWizardView2

#Preview {
    MainActor.assumeIsolated {
        WelcomeWizardView2(isWelcomeWizard: false)
            .environment(LocationManager())
            .modelContainer(previewContainer)
    }
    
}



struct PhotoView: View {
    
    @Binding var photo: UIImage?
    @State var useCamera: Bool
    @State private var photoPicker: PhotosPickerItem? = nil
    
    
//    
//    init(photo: Binding<UIImage?>) {
//        self._photo = photo
//        self._useCamera = State(initialValue: canUseCameraValue)
//        
//        print("what do we have here? \(canWeUseCamera())")
//        print("what about now? useCamera: \(useCamera)")
//    }
//    
    var body: some View {
        if useCamera {
            NavigationLink {
                ImagePicker(sourceType: .camera, selectedImage: $photo)
            } label: {
                if (photo != nil) {
                    SolidTextButton(text: "Retake Image", buttonLevel: .tertiary)
                } else {
                    SolidTextButton(text: "Take Image", buttonLevel: .primary)
                }
                
            }
            
        } else {
            PhotosPicker(selection: $photoPicker, matching: .images) {
                if (photo != nil) {
                    SolidTextButton(text: "Pick Image", buttonLevel: .tertiary)
                } else {
                    SolidTextButton(text: "Pick Image", buttonLevel: .primary)
                }
            } // photosPicker
            .onChange(of: photoPicker) { oldValue, newValue in
                Task {
                    if let data = try? await photoPicker?.loadTransferable(type: Data.self) {
                        photo = UIImage(data: data)
                    } // if we can get the data
                } // task
            } // on change of photo picker
        } // if/else useCamera
    } // body
} // DeliveredView
