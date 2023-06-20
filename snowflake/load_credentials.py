import toml
import os
directory = os.path.join(os.getcwd() + "/.streamlit")
if not os.path.exists(directory):
    os.makedirs(directory)
    
secrets = toml.load("secrets.toml")

output_file_name = os.path.join(directory+"/secrets.toml")
with open(output_file_name, "w") as toml_file:
    toml.dump(secrets, toml_file)