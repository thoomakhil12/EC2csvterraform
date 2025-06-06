import csv
import json
 
csv_file = "instances.csv"
instances = []
 
with open(csv_file, newline='') as f:
    reader = csv.DictReader(f)
    for row in reader:
        instances.append({
            "name": row["name"],
            "instance_type": row["instance_type"],
            "region": row["region"],
            "vpc_cidr": row["vpc_cidr"],
            "subnet_cidr": row["subnet_cidr"],
            "availability_zone": row["availability_zone"]
        })
 
with open("generated.tfvars.json", "w") as f:
    json.dump({"instances": instances}, f, indent=2)