import SwiftUI

public struct NewsListView: View {
    @ObservedObject var viewModel: NewsListViewModel
    let onSelect: (String) -> Void
    let onClose: () -> Void

    public init(viewModel: NewsListViewModel, onSelect: @escaping (String) -> Void, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            } else {
                List(viewModel.articles, id: \.id) { article in
                    Button {
                        onSelect(article.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(article.publishedAt)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    .listRowBackground(Color.black)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("News")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
