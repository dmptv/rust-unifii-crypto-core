import SwiftUI

public struct NewsArticleDetailView: View {
    @ObservedObject var viewModel: NewsArticleDetailViewModel

    public init(viewModel: NewsArticleDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let article = viewModel.article {
                    Text(article.title)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(article.publishedAt)
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text(article.summary)
                        .font(.body)
                        .foregroundStyle(.gray)
                    if let url = URL(string: article.url) {
                        Link("Read full article", destination: url)
                            .font(.callout.bold())
                    }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(viewModel.article?.title ?? "Article")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
}
