//
//  ViewController.swift
//  PagingExample
//
//  Created by Dao Duy Duong on 2/15/19.
//  Copyright © 2019 Nover, Inc. All rights reserved.
//

import UIKit

/*
 "vote_count": 1094,
 "id": 537996,
 "video": false,
 "vote_average": 7.3,
 "title": "A Balada de Buster Scruggs",
 "popularity": 26.311,
 "poster_path": "/voxl654m7p36y8FLu8oQD7dfwwK.jpg",
 "original_language": "en",
 "original_title": "The Ballad of Buster Scruggs",
 "genre_ids": [
 35,
 18,
 37
 ],
 "backdrop_path": "/90kmxuSwU28dVy1ghVSHI4x1wb8.jpg",
 "adult": false,
 "overview": "Os aclamados irmãos Joel e Ethan Coen idealizam uma antologia faroeste em seis segmentos focada na fronteira americana. Acompanhando de foras da lei, a colonizadores, até todo tipo de personalidade do velho oeste, essa série de histórias vai desde profundas reflexões até o mais completo absurdo.",
 "release_date": "2018-11-09"
 },*/

struct MovieModel {
  let voteCount: Int
  let id: Int
  let isVideo: Bool
  let voteAverage: Double
  let title: String
  let popularity: Double
  let poster: String
  let originalLang: String
  let originalTitle: String
  let isAdult: Bool
  let overview: String
  
  static func fromJSON(_ JSON: [String: Any]) -> MovieModel {
    return MovieModel(
      voteCount: JSON["vote_count"] as! Int,
      id: JSON["id"] as! Int,
      isVideo: JSON["video"] as! Bool,
      voteAverage: JSON["vote_average"] as! Double,
      title: JSON["title"] as! String,
      popularity: JSON["popularity"] as! Double,
      poster: JSON["poster_path"] as! String,
      originalLang: JSON["original_language"] as! String,
      originalTitle: JSON["original_title"] as! String,
      isAdult: JSON["adult"] as! Bool,
      overview: JSON["overview"] as! String)
  }
}

class ViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  
  var page = 0
  var isLoading = false
  var done = false
  var itemsSource: [MovieModel] = []
  
  let apiService = ApiService()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    loadNextPage()
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let scrollViewHeight = scrollView.frame.size.height
    let scrollContentSizeHeight = scrollView.contentSize.height
    let scrollOffset = scrollView.contentOffset.y
    
    let scrollSize = scrollOffset + scrollViewHeight
    
    // at the bottom
    if scrollSize >= scrollContentSizeHeight - 200 {
      loadNextPage()
    }
  }
  
  private func loadNextPage() {
    if isLoading || done { return }
    
    isLoading = true
    page += 1
    apiService.loadMovies(page, success: onSuccess) { (error) in
      print(error.localizedDescription)
      self.page -= 1
      self.isLoading = false
    }
  }
  
  private func onSuccess(_ movies: [MovieModel]) {
    if movies.count == 0 {
      done = true
    }
    
    let startIndex = itemsSource.count == 0 ? 0 : itemsSource.count
    
    // append to current sources
    itemsSource.append(contentsOf: movies)
    
    // add cells to table view
    let indexPaths = Array(startIndex...(startIndex + movies.count - 1)).compactMap { IndexPath(row: $0, section: 0) }
    tableView.insertRows(at: indexPaths, with: .bottom)
    
    isLoading = false
  }
}

extension ViewController: UITableViewDelegate {
  
}

extension ViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return itemsSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: MovieCell.identifier, for: indexPath)
    if let cell = cell as? MovieCell {
      cell.model = itemsSource[indexPath.row]
    }
    return cell
  }
}

class MovieCell: UITableViewCell {
  
  static let identifier = "MovieCell"
  
  var model: MovieModel? {
    didSet { updateContent() }
  }
  
  private func updateContent() {
    textLabel?.text = model?.title
    detailTextLabel?.text = model?.overview
  }
}

class ApiService {
  
  func loadMovies(_ page: Int = 1, success: @escaping (([MovieModel]) -> ()), failure: ((Error) -> ())? = nil) {
    let urlString = "https://api.themoviedb.org/3/discover/movie?api_key=270f002e0938b95112fa5b6f7447c42a&language=pt-BR&sort_by=popularity.desc&include_adult=true&page=\(page)&with_genres=37"
    let url = URL(string: urlString)!
    URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
      if let error = error {
        DispatchQueue.main.async {
          failure?(error)
        }
        
        return
      }
      
      guard
        let data = data,
        let JSON = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
      else {
        DispatchQueue.main.async {
          failure?(NSError(domain: "com.my.error", code: 100002, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response data."]))
        }
        return
      }
      
      let results = (JSON["results"] as? [[String: Any]]) ?? []
      let models = results.compactMap { MovieModel.fromJSON($0) }
      DispatchQueue.main.async { success(models) }
    }).resume()
  }
}
