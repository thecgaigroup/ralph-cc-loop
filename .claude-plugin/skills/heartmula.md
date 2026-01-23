---
name: heartmula
description: Generate AI music with lyrics using HeartMuLa on the GPU instance. Creates songs up to 10 minutes with vocals in 5 languages.
arguments:
  - name: description
    description: Description of the song (mood, style, theme)
    required: true
  - name: duration
    description: Song duration in seconds (30-600, default 60)
    required: false
---

# HeartMuLa Music Generation

You are a music generation assistant that creates songs using HeartMuLa AI on the aimusicgenerator GPU instance.

## Your Task

Generate a song based on the user's description: `$ARGUMENTS.description`
Duration: `$ARGUMENTS.duration` seconds (default: 60 if not specified)

## Step 1: Write Lyrics

Based on the user's description, write song lyrics with this structure:

```
[Verse 1]
(4-6 lines)

[Chorus]
(4 lines, catchy and memorable)

[Verse 2]
(4-6 lines)

[Chorus]
(repeat)

[Bridge]
(2-4 lines, emotional shift)

[Outro]
(2-4 lines)
```

For longer songs (>90 seconds), add more verses. For shorter songs (<45 seconds), use just verse + chorus.

## Step 2: Choose Style Tags

Select appropriate tags from these categories:

**Genre:** pop, rock, hip-hop, r&b, electronic, jazz, classical, country, folk, indie, metal, punk, reggae, soul, funk, blues, disco, house, techno, ambient

**Mood:** happy, sad, energetic, calm, romantic, angry, nostalgic, hopeful, melancholic, triumphant, peaceful, intense, playful, dramatic

**Tempo:** upbeat, slow, mid-tempo, fast, driving, laid-back

**Instrumentation:** piano, guitar, synth, orchestral, acoustic, electric, bass-heavy, drums, strings, brass

Combine 4-6 tags separated by commas.

## Step 3: Get GPU Instance ID

```bash
aws ssm get-parameter --name /aimusicgen/dev/ec2/gpu-instance-id --query 'Parameter.Value' --output text
```

## Step 4: Generate the Song

Use AWS SSM to run HeartMuLa on the GPU instance. Replace the placeholders:

```bash
aws ssm send-command \
  --instance-ids <INSTANCE_ID> \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands":["curl -s -X POST http://localhost:8188/prompt -H \"Content-Type: application/json\" -d \"{\\\"prompt\\\": {\\\"1\\\": {\\\"class_type\\\": \\\"HeartMuLa_Generate\\\", \\\"inputs\\\": {\\\"lyrics\\\": \\\"<LYRICS_ESCAPED>\\\", \\\"tags\\\": \\\"<TAGS>\\\", \\\"version\\\": \\\"3B\\\", \\\"max_audio_length_seconds\\\": <DURATION>, \\\"temperature\\\": 1.0, \\\"topk\\\": 50, \\\"cfg_scale\\\": 1.5, \\\"seed\\\": <RANDOM_SEED>, \\\"keep_model_loaded\\\": true, \\\"offload_mode\\\": \\\"auto\\\"}}, \\\"2\\\": {\\\"class_type\\\": \\\"SaveAudio\\\", \\\"inputs\\\": {\\\"filename_prefix\\\": \\\"<FILENAME_PREFIX>\\\", \\\"audio\\\": [\\\"1\\\", 0]}}}}\""]}' \
  --timeout-seconds 600 \
  --output text \
  --query 'Command.CommandId'
```

**Important escaping rules:**
- Replace newlines in lyrics with `\\\\n`
- Escape all quotes properly for JSON
- Use a random seed between 1-99999
- Filename prefix should be snake_case (e.g., `happy_birthday_song`)

## Step 5: Wait for Generation

Generation takes approximately:
- 30 seconds of audio: ~1 minute
- 60 seconds of audio: ~2 minutes
- 120 seconds of audio: ~4 minutes
- 300 seconds of audio: ~10 minutes

Check the command status:
```bash
aws ssm get-command-invocation --command-id <COMMAND_ID> --instance-id <INSTANCE_ID> --output json | jq -r '.Status'
```

Wait until status is `Success`, then check for output files.

## Step 6: Find Output File

```bash
aws ssm send-command \
  --instance-ids <INSTANCE_ID> \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands":["ls -la /opt/ComfyUI/output/ | grep <FILENAME_PREFIX>"]}' \
  --output text \
  --query 'Command.CommandId'
```

## Step 7: Upload to S3 and Get Download Link

```bash
aws ssm send-command \
  --instance-ids <INSTANCE_ID> \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands":["aws s3 cp /opt/ComfyUI/output/<FULL_FILENAME> s3://aimusicgen-assets-936321854814/heartmula-songs/<FILENAME>"]}' \
  --timeout-seconds 60 \
  --output text \
  --query 'Command.CommandId'
```

Then generate a presigned URL:
```bash
aws s3 presign s3://aimusicgen-assets-936321854814/heartmula-songs/<FILENAME> --expires-in 3600
```

## Step 8: Present Results

Show the user:
1. The lyrics you wrote
2. The style tags used
3. The download link (valid for 1 hour)
4. Generation stats (duration, time taken)

## HeartMuLa Parameters Reference

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| max_audio_length_seconds | 10-600 | 240 | Song duration |
| temperature | 0.1-2.0 | 1.0 | Creativity (higher = more varied) |
| topk | 1-250 | 50 | Token sampling diversity |
| cfg_scale | 1.0-10.0 | 1.5 | How closely to follow tags |
| seed | 0-max_int | random | Reproducibility seed |
| version | 3B, 7B | 3B | Model size (3B installed) |
| keep_model_loaded | bool | true | Keep in VRAM for faster next gen |
| offload_mode | auto, aggressive | auto | VRAM management |

## Supported Languages

HeartMuLa supports lyrics in:
- English (EN)
- Chinese (CN)
- Japanese (JP)
- Korean (KR)
- Spanish (ES)

## Example

User: "Create an upbeat birthday song for my friend Sarah"

1. **Lyrics:**
```
[Verse 1]
Today is your special day Sarah
The sun is shining just for you
Make a wish and blow the candles out
All your dreams are coming true

[Chorus]
Happy birthday Sarah
It's time to celebrate
Happy birthday Sarah
Today is gonna be great

[Verse 2]
Another year of memories made
With friends and family by your side
Laughter joy and love surround you
On this magical birthday ride

[Chorus]
Happy birthday Sarah
It's time to celebrate
Happy birthday Sarah
Today is gonna be great

[Outro]
Make a wish Sarah
Happy birthday to you
```

2. **Tags:** `pop, upbeat, happy, celebratory, acoustic, feel-good`

3. **Duration:** 60 seconds

4. **Seed:** 42069 (random)

Then execute the generation commands and provide the download link.
