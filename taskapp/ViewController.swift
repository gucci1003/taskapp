// タスク一覧画面のViewに必要な画面用・通知用パーツを効率的に実装するため、Xcodeで予め用意されているクラスを使用できるよう、ライブラリを有効化する
import UIKit
import UserNotifications

// タスク一覧画面のViewに必要なデータの保存・引き出しを効率的に実装するため、Realmで予め用意されているクラスを使用できるよう、ライブラリを有効化する
import RealmSwift


// ★クラスの宣言時に、プロトコルをあわせて表記する意義はよくわからない
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    var searchBar = UISearchBar()

    // 個別のデータに対して削除などの変更を加えられるよう、Realmインスタンスを取得しておく
    let realm = try! Realm()
    
    // データの一覧の情報（何個のタスクがあるか、など）を取得できるように、データを配列として定義しておく
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ★delegateやdatasourceがこのクラス内で定義されているよ、ってことだと思うが具体的にどれのことを指しているのか？
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        searchBar.placeholder = "検索"

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // タスク編集画面に遷移する際に、既存タスクデータの呼び出し・新規タスクデータの初期設定値を次のViewのControllerに渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        
        // ★これってなんのために宣言しているんだっけ？
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        // cellSegueが呼ばれる画面遷移、すなわち既存のタスクデータの編集画面への遷移の場合に、タスクデータを呼び出す
        if segue.identifier == "cellSegue" {
            
            // ★タップされたタスクのRowをindexPathとして定義する？
            let indexPath = self.tableView.indexPathForSelectedRow
            
            // 配列taskArrayのindexPathのRowに格納されているデータを引き出す
            inputViewController.task = taskArray[indexPath!.row]
        }
        
        //　cellSegueが呼ばれない画面遷移、すなわち新規のタスクデータの作成画面への遷移の場合に、各データの初期設定値を決める
        else {
            
            // タスクの日付として現在時間を設定する
            let task = Task()
            task.date = NSDate()
            
            // タスクのidを既存タスクの次の値に設定する
            if taskArray.count != 0 {
                task.id = taskArray.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // ★reloadDataはどこで定義されているメソッド？（Project独自のメソッドではないみたい）
        tableView.reloadData()
    }
    
    // カテゴリ検索に合致するタスクを表示するメソッド
    // 検索ボタンが押された時に呼ばれる
    // ☆入力するたびに絞込みしたいならtextchange、空文字でも検索できるようにする
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        searchBar.showsCancelButton = true
        
        // NSPredicateを使って検索条件を指定します
        let predicate = NSPredicate(format: "category BEGINSWITH %@", searchBar.text!)
        // 検索結果として絞り込まれたデータを配列として定義する
        taskArray = try! Realm().objects(Task.self).filter(predicate).sorted(byKeyPath: "date", ascending: false)
        
        self.tableView.reloadData()
        searchBar.showsCancelButton = true
    }
    
    // キャンセルボタンが押された時に呼ばれる
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        self.view.endEditing(true)
        searchBar.text = ""
        taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
        self.tableView.reloadData()
    }
    
    // テキストフィールド入力開始前に呼ばれる
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }


    // MARK: UITableViewDataSourceプロトコルのメソッド
    // 一覧画面に表示するデータの数（＝セルの数）を設定するメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // taskArrayに格納されているデータの数をタスク一覧画面のRowの数として定義する
        return taskArray.count

    }
    
    // 一覧画面に表示するセルの内容を設定するメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // ★セルの内容を入れるための箱（定数）を定義している？データの数だけ繰り返す必要があると思うけど、それはどう対応している？
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
        
        // セルのタイトルラベルに入れる値をtaskArrayから引き出す
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        // ★DateのフォーマットをDateFormatterという既存のクラスから引き出して定義している？
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        // ★引き出したフォーマットを反映しないのか？
        let dateString:String = formatter.string(from: task.date as Date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // 削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ★ローカル通知をキャンセルする、とは？
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // ★writeとかdeleteってメソッド定義してないはずだけど？
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
}

