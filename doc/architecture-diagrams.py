from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.container import Docker
from diagrams.onprem.network import Internet, Nginx, Haproxy
from diagrams.generic.network import VPN
from diagrams.generic.os import Ubuntu
from diagrams.generic.database import SQL

# Configuration du diagramme
with Diagram("Architecture Cloud Native - All in One VM - Denv-r", show=False, direction="TB"):
    with Cluster("Denv-r cloud provider"):

        with Cluster("VM"):
            VM = [Docker("Frontend"),
                  Docker("Backend"),
                  SQL("SQLite")]

        # Bastion pour sécuriser SSH
        bastion_vm = VPN("Bastion\n(SSH Access)")

    # Communication SSH (port 22)
    ssh_traffic = Internet("SSH (22)")
    ssh_traffic >> bastion_vm >> VM

    # Communication ports 80/443
    web_traffic = Internet("HTTP/HTTPS")
    web_traffic >> VM[0]





# Configuration du diagramme
with Diagram("Architecture Cloud Native - Multiple VMs - Denv-r", show=False, direction="LR"):
    with Cluster("Denv-r cloud provider"):

        with Cluster("Bastion"):
            # Bastion pour sécuriser SSH
            bastion_vm = VPN("SSH Access")
        
        with Cluster("Frontend"):
            waf_vm = Nginx("Nginx WAF")
            loadbalancer = Haproxy("LoadBalancer")

        with Cluster("Backend"): 
            with Cluster(""):       
                front_vm = Ubuntu("NextJS-1\nport:443")
                front_vms = [Ubuntu("NextJS-2"),
                            Ubuntu("NextJS-n")]            
            back_vm = Ubuntu("Strapi\nport:1307")

        with Cluster("Bdd"):
            bdd = SQL("SQLite\n(port:3306)")

    # Communication SSH (port 22)
    ssh_traffic = Internet("SSH (22)")
    ssh_traffic >> Edge(color="red") >> bastion_vm >> Edge(color="red") >> front_vm
    bastion_vm >> Edge(color="red") >> waf_vm

    # Communication ports 80/443
    web_traffic = Internet("HTTP/HTTPS")
    # web_traffic >> Edge(color="darkgreen") >> waf_vm >> Edge(color="darkgreen") >> front_vms
    web_traffic >> Edge(color="darkgreen") >> waf_vm >> Edge(color="darkgreen") >> loadbalancer >> Edge(color="darkgreen") >> front_vm  
    waf_vm >> Edge(label="/api") >> back_vm

    # Communication base de données
    back_vm >> bdd
    bastion_vm >> Edge(color="red") >> bdd