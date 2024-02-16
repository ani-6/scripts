import sys, os
from mega import Mega

email = sys.argv[1]
password = sys.argv[2]
folder_to_upload = sys.argv[3]
directory = sys.argv[4]


def login_to_mega(email,password):
    try:
        mega = Mega()
        m = mega.login(email, password)
        return m
    except:
        print('Bad login!')
        sys.exit(0)

def get_all_files_to_upload():
    try:
        dir_list = [f for f in os.listdir(directory) if not f.startswith('.')]
        return dir_list
    except Exception as error:
        print('Error: ',error)

def upload_files(list,m):
    if len(list)==0:
        sys.exit(0)
    try:
        folder = m.find(folder_to_upload)
        for f in list:
            upload_file = directory + '/' + f
            print(upload_file)
            file = m.upload(upload_file, folder[0])
        return "All files uploaded sucessfully" 
    except Exception as error:
        print('Error: ',error)


if __name__ == "__main__":
    try:
        m = login_to_mega(email,password)
        list = get_all_files_to_upload()
        result = upload_files(list,m)
        print(result)
    except KeyboardInterrupt:
        print("\nKeyboard interrupt received, exiting.")
        sys.exit(0)
    except:
        print("Something else went wrong")