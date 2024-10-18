import sys, os
from mega import Mega

email = sys.argv[1]
password = sys.argv[2]
folder_to_upload = sys.argv[3]
directory = sys.argv[4]
data_dir_path = sys.argv[5]


def login_to_mega(email,password):
    try:
        mega = Mega()
        m = mega.login(email, password)
        return m
    except:
        print('Bad login!')
        sys.exit(0)

def get_files_to_upload():
    try:
        path = data_dir_path + "gitea/" + directory
        files = os.listdir(path)
        files_with_times = [(file, os.path.getmtime(os.path.join(path, file))) for file in files]
        
        sorted_files = sorted(files_with_times, key=lambda x: x[1], reverse=True)
        
        return [file[0] for file in sorted_files[:1]]
    except Exception as error:
        print('Error: ',error)

def upload_files(list,m):
    if len(list)==0:
        sys.exit(0)
    try:
        folder = m.find(folder_to_upload)
        for f in list:
            upload_file = data_dir_path + "gitea/" + directory + '/' + f
            file = m.upload(upload_file, folder[0])
        return "Success"
    except Exception as error:
        print('Error: ',error)


if __name__ == "__main__":
    try:
        m = login_to_mega(email,password)
        list = get_files_to_upload()
        result = upload_files(list,m)
        print(result)
    except KeyboardInterrupt:
        print("\nKeyboard interrupt received, exiting.")
        sys.exit(0)
    except:
        print("Something else went wrong")