# Doc as code

## Diagram as code
### Install requirements

```bash
sudo apt update
sudo apt install graphviz
sudo apt install xdg-utils # if 'with Diagram("myDiagram", show=True)', either 'with Diagram("myDiagram", show=False)'

mkdir -p /opt/venv
python3 -m venv /opt/venv/denvr
pip install --upgrade pip
pip install --upgrade -r requirements.txt
```

## Generate diagrams

```bash
python3 architecture-diagrams.py 
```

### Edit diagrams

You can edit the `architecture-diagrams.py` file following the [official documentation](https://diagrams.mingrammer.com/docs)