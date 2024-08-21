
# List of sample names
SAMPLES = ["ERR7672970", "SRR5234505", "SRR8553642", "SRR14267071", "SRR20746679", "SRR22278231"]

# Rule to specify the final output files for all samples
rule all:
    input:
        # Trimmed reads + sketches
        expand("sketch/{sample}.sig", sample=SAMPLES),
        # Gather results for all samples
        expand("gather/{sample}.k31.gather.csv", sample=SAMPLES),
        # Taxonomy results for all samples
        expand("tax/{sample}.lingroup.tsv", sample=SAMPLES)

# Rule to trim reads for each sample:
rule trim_reads:
    input:
        in1="rawdata/{sample}_1.fastq.gz",
        in2="rawdata/{sample}_2.fastq.gz"
    output:
        out1="quality/{sample}_1.trim.fastq.gz",
        out2="quality/{sample}_2.trim.fastq.gz",
        json="quality/{sample}.fastp.json",
        html="quality/{sample}.fastp.html"
    conda: "fastp-env.yaml"
    shell:
        """
        fastp --in1 {input.in1}  --in2 {input.in2}  \
        --out1 {output.out1} --out2 {output.out2}  \
        --detect_adapter_for_pe  --qualified_quality_phred 4 \
        --length_required 31 --correction \
        --json {output.json} --html {output.html}
        """

# Rule to sketch trimmed reads using Sourmash (see separate notes from slack**)
rule sourmash_sketch:
    input:
        in1="quality/{sample}_1.trim.fastq.gz",
        in2="quality/{sample}_2.trim.fastq.gz"
    output:
        out1="sketch/{sample}.sig"
    conda: "sourmash-env.yaml"
    shell:
        """
        sourmash sketch dna {input.in1} {input.in2} -o {output.out1} --name {wildcards.sample} -p k=31,scaled=1000,abund
        """

rule sourmash_gather:
    input:
        sig="sketch/{sample}.sig",
        database="/group/ctbrowngrp4/mmerid/Ralstonia/databases/ralstonia.zip"
    output:
        out="gather/{sample}.k31.gather.csv"
    conda: "sourmash-env.yaml"
    shell:
        """
        sourmash gather {input.sig} {input.database} -k 31 --dna --output {output.out}
        """

# Rule to run Sourmash tax metagenome
rule sourmash_tax_metagenome:
    input:
        gather="gather/{sample}.k31.gather.csv",
        taxonomy="/group/ctbrowngrp4/mmerid/Ralstonia/smashLIN/ralstonia32.lin-taxonomy.csv",
        lingroup="/group/ctbrowngrp4/mmerid/Ralstonia/smashLIN/ralstonia.lingroups.csv"
    output:
        out="tax/{sample}.lingroup.tsv"
    conda: "sourmash-env.yaml"
    shell:
        """
        sourmash tax metagenome -g {input.gather} -t {input.taxonomy} \
        --lins --lingroup {input.lingroup} > {output.out}
        """


