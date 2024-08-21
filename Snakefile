import os

# define some variables
samples_file = "rs6.samples.txt"
ralstonia_database = "databases/ralstonia32.zip"

out_dir = "output.ralstonia_sra"

# now, get the sample names from the signature file paths
SAMPLES = [os.path.splitext(os.path.basename(path))[0] for path in open(samples_file)]
print(SAMPLES) # make sure these look right

rule all:
    input:
        expand(f"{out_dir}/gather/{{sample}}.gather.csv", sample=SAMPLES)

rule branchwater_fastmultigather:
    input:
        samples = samples_file,
        database = ralstonia_database
    output: expand(f"{out_dir}/gather/{{sample}}.gather.csv", sample=SAMPLES)
    conda: "branchwater.yaml"
    params:
        outd=f"{out_dir}/gather",
    threads: 10
    shell:
        """
        sourmash scripts fastmultigather -k 21 \
                         --scaled 1000 {input.samples} \
                         {input.database}
        mv *gather.csv *prefetch.csv {params.outd}
        """
