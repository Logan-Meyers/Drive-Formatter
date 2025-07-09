import subprocess
import re

def list_disks():
    commands = ['list disk']
    output, error = run_diskpart(commands)
    
    if error:
        print("Error listing disks:", error)
        return []

    disks = []
    # Regex to extract disk information
    disk_pattern = re.compile(r'^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\w+)', re.MULTILINE)
    
    for match in disk_pattern.finditer(output):
        disk_number = int(match.group(1))
        if disk_number == 0:
            continue  # Skip disk 0
        size = match.group(2)
        free = match.group(3)
        gpt = match.group(4) == 'Gpt'
        disks.append({
            'Disk Number': disk_number,
            'Size': size,
            'Free': free,
            'GPT': gpt
        })
    
    return disks

def list_partitions(disk_number):
    commands = [
        f'select disk {disk_number}',
        'list partition'
    ]
    output, error = run_diskpart(commands)

    if error:
        print("Error selecting disk:", error)
        return []

    partitions = []
    # Regex to extract partition information
    partition_pattern = re.compile(r'^\s*(\d+)\s+(\w+)\s+(\d+)', re.MULTILINE)

    for match in partition_pattern.finditer(output):
        partition_number = int(match.group(1))
        partition_type = match.group(2)
        size = match.group(3)
        partitions.append({
            'Partition Number': partition_number,
            'Type': partition_type,
            'Size': size
        })

    return partitions

def get_partition_attributes(disk_number, partition_number):
    commands = [
        f'select disk {disk_number}',
        f'select partition {partition_number}',
        'detail partition'
    ]
    output, error = run_diskpart(commands)

    if error:
        print("Error selecting partition:", error)
        return {}

    # Extracting attributes
    attributes = {}
    type_pattern = re.compile(r'Type\s+:\s+(.+)', re.MULTILINE)
    label_pattern = re.compile(r'Volume\s+Label\s+:\s+(.+)', re.MULTILINE)

    type_match = type_pattern.search(output)
    label_match = label_pattern.search(output)

    if type_match:
        attributes['Type'] = type_match.group(1).strip()
    if label_match:
        attributes['Label'] = label_match.group(1).strip()

    return attributes


# ----- main run disk part function that accepts commands
def run_diskpart(commands):
    with open('diskpart_commands.txt', 'w') as f:
        f.write('\n'.join(commands))

    process = subprocess.Popen(
        ['diskpart', '/s', 'diskpart_commands.txt'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    stdout, stderr = process.communicate()
    subprocess.run(['del', 'diskpart_commands.txt'], shell=True)
    return stdout, stderr