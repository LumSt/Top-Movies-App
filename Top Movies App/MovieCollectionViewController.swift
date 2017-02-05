//
//  MovieCollectionViewController.swift
//  Top Movies App
//
//  Created by Lum Situ on 1/30/17.
//  Copyright © 2017 Lum Situ. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MovieCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate{
    
    @IBOutlet weak var MovieCollectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies:[NSDictionary]?
    
    var filteredMovies:[NSDictionary]?
    
    var searchController: UISearchController!
    
    var endpoint: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        self.filteredMovies = self.movies
        
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction), for: UIControlEvents.valueChanged)
        // add refresh control to collection view
        MovieCollectionView.insertSubview(refreshControl, at: 0)
        MovieCollectionView.dataSource = self
        MovieCollectionView.delegate = self
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    print(dataDictionary)
                    
                    self.movies = dataDictionary["results"] as? [NSDictionary]
                    self.filteredMovies = self.movies
                    self.MovieCollectionView.reloadData()
                    
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }
        }
        
        
        
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //if let movies = movies {
        //    return movies.count
        //} else {
        //    return 0
        //}
        
        return filteredMovies?.count ?? 0
    }
    
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = MovieCollectionView.dequeueReusableCell(withReuseIdentifier: "MovieCollectionViewCell", for: indexPath) as! MovieCollectionViewCell
        
        let movie = filteredMovies?[indexPath.row]
        let title = movie?["title"] as! String
        
        if let posterPath = movie?["poster_path"] as? String {
            let baseUrl = "http://image.tmdb.org/t/p/w500"
            let imageUrl = NSURL(string: baseUrl + posterPath)
            cell.posterCollectionView.setImageWith(imageUrl as! URL)
        
            let imageRequest = NSURLRequest(url: imageUrl as! URL)
        
            cell.posterCollectionView.setImageWith(
                imageRequest as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                
                // imageResponse will be nil if the image is cached
                if imageResponse != nil {
                    print("Image was NOT cached, fade in image")
                    cell.posterCollectionView.alpha = 0.0
                    cell.posterCollectionView.image = image
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        cell.posterCollectionView.alpha = 1.0
                    })
                } else {
                    print("Image was cached so just update the image")
                    cell.posterCollectionView.image = image
                }
        },
            failure: { (imageRequest, imageResponse, error) -> Void in
                // do something for the failure condition
        })
        
        }
        print(title)
        
        return cell
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
        // ... Create the NSURLRequest (myRequest) ...
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")!
        let myRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: myRequest,completionHandler: { (data, response, error) in
                                                            
        // ... Use the new data to update the data source ...
                                                            
                                                            
        // Reload the tableView now that there is new data
        self.MovieCollectionView.reloadData()
                                                            
        // Tell the refreshControl to stop spinning
        refreshControl.endRefreshing()
                                                            
        });
        task.resume()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        // When there is no text, filteredMovies is the same as the original movies
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
        filteredMovies = searchText.isEmpty ? movies : movies?.filter({(movie: NSDictionary) -> Bool in
            // If dataItem matches the searchText, return true to include it
            return (movie["title"] as! String).range(of: searchText, options: .caseInsensitive) != nil
        })
        
        MovieCollectionView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UICollectionViewCell
        let indexPath = MovieCollectionView.indexPath(for: cell)
        let movie = movies?[(indexPath?.row)!]
        let detaiViewController = segue.destination as! DetailViewController
        detaiViewController.movies = movie
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("prepare for segue called")
    }
 

}

