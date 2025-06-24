//
//  mainView.swift
//  CommentCode
//
//  Created by Mohammad Awaan Nisar on 19/06/25.
//

import SwiftUI

struct mainView: View {
    @StateObject private var viewModel = CommentCodeViewModel()
    
    var body: some View {
        VStack {
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            HStack {
                ZStack {
                    TextEditor(text: $viewModel.codeInput)
                        .cornerRadius(8)
                        .padding(.top, 5)
                        .padding(.bottom, 2)
                        .padding(.leading, 10)
                        .padding(.trailing, 3)
                        .frame(height: 520)
                    Text("Paste Your Code Here")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                        .opacity(10/100)
                }
                Image("arr")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height:100)
                ZStack {
                    TextEditor(text: $viewModel.responseOutput )
                        .cornerRadius(8)
                        .padding(.top, 5)
                        .padding(.bottom, 2)
                        .padding(.trailing, 10)
                        .padding(.leading, 3)
                        .frame(height: 520)
                    Text("Result")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                        .opacity(10/100)
                }
            }
            if viewModel.isResponsing {
                ProgressView("Generating response...")
                    .progressViewStyle(DefaultProgressViewStyle())
            }
            HStack {
                if viewModel.responseHasGenerated {
                    Button(action: viewModel.reset) {
                        Text("Clear")
                    }
                    Button(action: viewModel.copyToClipboard) {
                        Text(viewModel.isCopied ? "Copied" : "Copy")
                    }
                    .foregroundColor(viewModel.isCopied ? .green : .blue)
                }
                else {
                    HStack {
                        Button(action: viewModel.generateComments) {
                            Text("Generate Comments")
                                //.frame(width: .infinity)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.blue)

                        }
                        .buttonStyle(.borderless).cornerRadius(5)
                        .padding(.bottom, 8)
                        .disabled(viewModel.isResponsing || viewModel.codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Button(action: viewModel.explainCode) {
                            Text("Explain this Code")
                                //.frame(width: .infinity)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.blue)
                        }
                        .buttonStyle(.borderless).cornerRadius(5)
                        .padding(.bottom, 10)
                        .disabled(viewModel.isResponsing || viewModel.codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Button(action: viewModel.reset) {
                            Text("Clear all")
                                //.frame(width: .infinity)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.red)
                                
                        }
                        .buttonStyle(.borderless).cornerRadius(5)
                        .padding(.bottom, 10)
                        .disabled(viewModel.codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                }
            }
        }
        
    }
}

#Preview {
    mainView()
}
