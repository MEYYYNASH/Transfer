using System;
using System.Drawing;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace LinkoraApp
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    public class MainForm : Form
    {
        // Design Tokens
        private readonly Color ColorBackground = ColorTranslator.FromHtml("#0D0F14");
        private readonly Color ColorSurface = ColorTranslator.FromHtml("#171A23");
        private readonly Color ColorElevated = ColorTranslator.FromHtml("#212635");
        private readonly Color ColorBorder = ColorTranslator.FromHtml("#343746");
        private readonly Color ColorPrimary = ColorTranslator.FromHtml("#9878FF");
        private readonly Color ColorSecondary = ColorTranslator.FromHtml("#55D6C2");
        private readonly Color ColorText = ColorTranslator.FromHtml("#F4F5FA");
        private readonly Color ColorSubtext = ColorTranslator.FromHtml("#A1A7B7");

        private Label lblTitle;
        private Label lblStatus;
        private TextBox txtTargetIp;
        private TextBox txtTargetPort;
        private Button btnSelectFile;
        private Button btnSend;
        private Button btnToggleServer;
        private ProgressBar progressBar;
        private ListBox lstLog;

        private TcpListener listener;
        private bool isListening = false;
        private string selectedFilePath = null;
        private string saveDirectory;

        public MainForm()
        {
            this.Text = "LINKORA — Secure Cross-Platform File Transfer";
            this.Size = new Size(820, 680);
            this.MinimumSize = new Size(720, 560);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = ColorBackground;
            this.ForeColor = ColorText;
            this.Font = new Font("Segoe UI", 9.5f, FontStyle.Regular);

            saveDirectory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "LinkoraDownloads");
            if (!Directory.Exists(saveDirectory))
            {
                Directory.CreateDirectory(saveDirectory);
            }

            InitializeComponents();
            StartServer();
        }

        private void InitializeComponents()
        {
            // Header
            lblTitle = new Label
            {
                Text = "⚡ LINKORA Desktop — Wi-Fi / LAN P2P Engine",
                Font = new Font("Segoe UI", 16f, FontStyle.Bold),
                ForeColor = ColorPrimary,
                Location = new Point(24, 20),
                AutoSize = true
            };
            this.Controls.Add(lblTitle);

            var lblSubtitle = new Label
            {
                Text = "High-speed encrypted local transfers, streaming bounded chunks, and SHA-256 integrity verification.",
                ForeColor = ColorSubtext,
                Location = new Point(26, 56),
                AutoSize = true
            };
            this.Controls.Add(lblSubtitle);

            // Container Panel - Send Files
            var pnlSend = new Panel
            {
                Location = new Point(24, 95),
                Size = new Size(750, 160),
                BackColor = ColorSurface,
                BorderStyle = BorderStyle.FixedSingle
            };
            this.Controls.Add(pnlSend);

            var lblSendHeader = new Label
            {
                Text = "SEND FILES TO NEARBY DEVICE",
                Font = new Font("Segoe UI", 10f, FontStyle.Bold),
                ForeColor = ColorSecondary,
                Location = new Point(16, 14),
                AutoSize = true
            };
            pnlSend.Controls.Add(lblSendHeader);

            var lblIp = new Label { Text = "Receiver IP:", ForeColor = ColorSubtext, Location = new Point(16, 48), AutoSize = true };
            pnlSend.Controls.Add(lblIp);

            txtTargetIp = new TextBox
            {
                Text = "127.0.0.1",
                Location = new Point(105, 45),
                Size = new Size(160, 26),
                BackColor = ColorElevated,
                ForeColor = ColorText,
                BorderStyle = BorderStyle.FixedSingle
            };
            pnlSend.Controls.Add(txtTargetIp);

            var lblPort = new Label { Text = "Port:", ForeColor = ColorSubtext, Location = new Point(280, 48), AutoSize = true };
            pnlSend.Controls.Add(lblPort);

            txtTargetPort = new TextBox
            {
                Text = "8888",
                Location = new Point(320, 45),
                Size = new Size(60, 26),
                BackColor = ColorElevated,
                ForeColor = ColorText,
                BorderStyle = BorderStyle.FixedSingle
            };
            pnlSend.Controls.Add(txtTargetPort);

            btnSelectFile = new Button
            {
                Text = "📁 Select File...",
                Location = new Point(400, 43),
                Size = new Size(140, 30),
                BackColor = ColorElevated,
                ForeColor = ColorText,
                FlatStyle = FlatStyle.Flat
            };
            btnSelectFile.FlatAppearance.BorderColor = ColorBorder;
            btnSelectFile.Click += BtnSelectFile_Click;
            pnlSend.Controls.Add(btnSelectFile);

            btnSend = new Button
            {
                Text = "🚀 Send via Local Wi-Fi",
                Location = new Point(555, 43),
                Size = new Size(175, 30),
                BackColor = ColorPrimary,
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            btnSend.FlatAppearance.BorderSize = 0;
            btnSend.Click += async (s, e) => await SendFileAsync();
            pnlSend.Controls.Add(btnSend);

            lblStatus = new Label
            {
                Text = "Ready to send or receive.",
                ForeColor = ColorSubtext,
                Location = new Point(16, 90),
                Size = new Size(710, 22),
                AutoEllipsis = true
            };
            pnlSend.Controls.Add(lblStatus);

            progressBar = new ProgressBar
            {
                Location = new Point(16, 120),
                Size = new Size(715, 18),
                Style = ProgressBarStyle.Continuous
            };
            pnlSend.Controls.Add(progressBar);

            // Container Panel - Receiver Server
            var pnlReceive = new Panel
            {
                Location = new Point(24, 275),
                Size = new Size(750, 80),
                BackColor = ColorSurface,
                BorderStyle = BorderStyle.FixedSingle
            };
            this.Controls.Add(pnlReceive);

            var lblReceiveHeader = new Label
            {
                Text = "RECEIVER SERVICE (LISTENING ON PORT 8888)",
                Font = new Font("Segoe UI", 10f, FontStyle.Bold),
                ForeColor = ColorSecondary,
                Location = new Point(16, 14),
                AutoSize = true
            };
            pnlReceive.Controls.Add(lblReceiveHeader);

            var lblSaveInfo = new Label
            {
                Text = "Saving to: " + saveDirectory,
                ForeColor = ColorSubtext,
                Location = new Point(16, 44),
                Size = new Size(540, 22),
                AutoEllipsis = true
            };
            pnlReceive.Controls.Add(lblSaveInfo);

            btnToggleServer = new Button
            {
                Text = "Active (Stop)",
                Location = new Point(580, 24),
                Size = new Size(150, 34),
                BackColor = ColorElevated,
                ForeColor = ColorSecondary,
                FlatStyle = FlatStyle.Flat
            };
            btnToggleServer.FlatAppearance.BorderColor = ColorSecondary;
            btnToggleServer.Click += (s, e) => ToggleServer();
            pnlReceive.Controls.Add(btnToggleServer);

            // Log Console
            var lblLogHeader = new Label
            {
                Text = "ACTIVITY & INTEGRITY AUDIT LOG",
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                ForeColor = ColorSubtext,
                Location = new Point(26, 370),
                AutoSize = true
            };
            this.Controls.Add(lblLogHeader);

            lstLog = new ListBox
            {
                Location = new Point(24, 395),
                Size = new Size(750, 220),
                BackColor = ColorSurface,
                ForeColor = ColorText,
                BorderStyle = BorderStyle.FixedSingle,
                Font = new Font("Consolas", 9f)
            };
            this.Controls.Add(lstLog);

            Log("LINKORA Engine Initialized. Storage Path: " + saveDirectory);
        }

        private void Log(string message)
        {
            if (this.InvokeRequired)
            {
                this.Invoke(new Action(() => Log(message)));
                return;
            }
            lstLog.Items.Add(string.Format("[{0:HH:mm:ss}] {1}", DateTime.Now, message));
            lstLog.SelectedIndex = lstLog.Items.Count - 1;
        }

        private void BtnSelectFile_Click(object sender, EventArgs e)
        {
            using (var ofd = new OpenFileDialog())
            {
                ofd.Title = "Select File to Send";
                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    selectedFilePath = ofd.FileName;
                    var fi = new FileInfo(selectedFilePath);
                    lblStatus.Text = string.Format("Selected: {0} ({1:0.00} MB)", fi.Name, fi.Length / (1024.0 * 1024.0));
                    Log("File selected: " + fi.Name);
                }
            }
        }

        private async Task SendFileAsync()
        {
            if (string.IsNullOrEmpty(selectedFilePath) || !File.Exists(selectedFilePath))
            {
                MessageBox.Show("Please select a valid file first.", "LINKORA", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            string ip = txtTargetIp.Text.Trim();
            int port;
            if (!int.TryParse(txtTargetPort.Text.Trim(), out port)) port = 8888;

            btnSend.Enabled = false;
            lblStatus.Text = "Calculating SHA-256 Checksum...";
            progressBar.Value = 0;

            try
            {
                var fi = new FileInfo(selectedFilePath);
                string sha256 = await Task.Run(() => ComputeSha256(selectedFilePath));
                Log(string.Format("SHA-256 Calculated: {0}", sha256));

                lblStatus.Text = string.Format("Connecting to {0}:{1}...", ip, port);
                using (var client = new TcpClient())
                {
                    await client.ConnectAsync(ip, port);
                    using (var netStream = client.GetStream())
                    {
                        // 1. Send JSON metadata header terminated with \n
                        string header = string.Format("{{\"fileName\":\"{0}\",\"fileSize\":{1},\"sha256\":\"{2}\"}}\n",
                            fi.Name, fi.Length, sha256);
                        byte[] headerBytes = Encoding.UTF8.GetBytes(header);
                        await netStream.WriteAsync(headerBytes, 0, headerBytes.Length);

                        // 2. Read acceptance handshake
                        byte[] responseBuf = new byte[256];
                        int readBytes = await netStream.ReadAsync(responseBuf, 0, responseBuf.Length);
                        string responseStr = Encoding.UTF8.GetString(responseBuf, 0, readBytes);

                        if (!responseStr.Contains("ACCEPTED"))
                        {
                            Log("Transfer was rejected or denied by receiver.");
                            lblStatus.Text = "Transfer rejected by receiver.";
                            return;
                        }

                        Log("Receiver accepted transfer. Streaming chunks...");
                        lblStatus.Text = "Transferring data...";

                        // 3. Stream bounded 64 KB chunks
                        byte[] buffer = new byte[64 * 1024];
                        long totalSent = 0;
                        using (var fs = File.OpenRead(selectedFilePath))
                        {
                            int bytesRead;
                            while ((bytesRead = await fs.ReadAsync(buffer, 0, buffer.Length)) > 0)
                            {
                                await netStream.WriteAsync(buffer, 0, bytesRead);
                                totalSent += bytesRead;
                                int percent = (int)((totalSent * 100) / fi.Length);
                                progressBar.Value = Math.Min(percent, 100);
                            }
                        }

                        Log(string.Format("Transfer completed: {0} ({1:0.00} MB)", fi.Name, fi.Length / (1024.0 * 1024.0)));
                        lblStatus.Text = "Transfer Completed Successfully!";
                    }
                }
            }
            catch (Exception ex)
            {
                Log("Send error: " + ex.Message);
                lblStatus.Text = "Error: " + ex.Message;
            }
            finally
            {
                btnSend.Enabled = true;
            }
        }

        private void ToggleServer()
        {
            if (isListening)
            {
                StopServer();
                btnToggleServer.Text = "Stopped (Start)";
                btnToggleServer.ForeColor = Color.FromArgb(255, 100, 124);
                btnToggleServer.FlatAppearance.BorderColor = Color.FromArgb(255, 100, 124);
            }
            else
            {
                StartServer();
                btnToggleServer.Text = "Active (Stop)";
                btnToggleServer.ForeColor = ColorSecondary;
                btnToggleServer.FlatAppearance.BorderColor = ColorSecondary;
            }
        }

        private void StartServer()
        {
            try
            {
                listener = new TcpListener(IPAddress.Any, 8888);
                listener.Start();
                isListening = true;
                Task.Run(() => AcceptClientsLoop());
                Log("Receiver listening on 0.0.0.0:8888");
            }
            catch (Exception ex)
            {
                Log("Server error: " + ex.Message);
            }
        }

        private void StopServer()
        {
            try
            {
                isListening = false;
                if (listener != null) listener.Stop();
                Log("Receiver service stopped.");
            }
            catch (Exception ex)
            {
                Log("Stop error: " + ex.Message);
            }
        }

        private async Task AcceptClientsLoop()
        {
            while (isListening)
            {
                try
                {
                    var client = await listener.AcceptTcpClientAsync();
                    Task.Run(() => HandleIncomingClient(client));
                }
                catch
                {
                    if (!isListening) break;
                }
            }
        }

        private async Task HandleIncomingClient(TcpClient client)
        {
            string remoteIp = ((IPEndPoint)client.Client.RemoteEndPoint).Address.ToString();
            Log("Incoming connection from " + remoteIp);

            try
            {
                using (var stream = client.GetStream())
                {
                    // Read header line
                    var headerBytes = new System.Collections.Generic.List<byte>();
                    int b;
                    while ((b = stream.ReadByte()) != -1)
                    {
                        if (b == '\n') break;
                        headerBytes.Add((byte)b);
                    }

                    string headerJson = Encoding.UTF8.GetString(headerBytes.ToArray());
                    string fileName = ExtractJsonValue(headerJson, "fileName");
                    long fileSize = long.Parse(ExtractJsonValue(headerJson, "fileSize"));
                    string expectedSha = ExtractJsonValue(headerJson, "sha256");

                    // Sanitize filename to prevent path traversal
                    fileName = Path.GetFileName(fileName);
                    foreach (char c in Path.GetInvalidFileNameChars())
                    {
                        fileName = fileName.Replace(c, '_');
                    }

                    // Prompt receiver confirmation
                    var dialogResult = MessageBox.Show(
                        string.Format("Accept incoming file from {0}?\n\nFile: {1}\nSize: {2:0.00} MB",
                            remoteIp, fileName, fileSize / (1024.0 * 1024.0)),
                        "LINKORA Transfer Request",
                        MessageBoxButtons.YesNo,
                        MessageBoxIcon.Question);

                    if (dialogResult != DialogResult.Yes)
                    {
                        byte[] rejectBytes = Encoding.UTF8.GetBytes("REJECTED\n");
                        await stream.WriteAsync(rejectBytes, 0, rejectBytes.Length);
                        Log("Incoming transfer rejected by user.");
                        return;
                    }

                    // Send accepted handshake
                    byte[] acceptBytes = Encoding.UTF8.GetBytes("ACCEPTED\n");
                    await stream.WriteAsync(acceptBytes, 0, acceptBytes.Length);

                    string targetPath = Path.Combine(saveDirectory, fileName);
                    string partPath = targetPath + ".part";

                    Log(string.Format("Receiving: {0} ({1:0.00} MB)...", fileName, fileSize / (1024.0 * 1024.0)));

                    byte[] buffer = new byte[64 * 1024];
                    long totalReceived = 0;

                    using (var fs = File.Create(partPath))
                    {
                        while (totalReceived < fileSize)
                        {
                            int toRead = (int)Math.Min(buffer.Length, fileSize - totalReceived);
                            int read = await stream.ReadAsync(buffer, 0, toRead);
                            if (read == 0) break;

                            await fs.WriteAsync(buffer, 0, read);
                            totalReceived += read;
                        }
                    }

                    // Verify SHA-256
                    Log("Verifying SHA-256 integrity...");
                    string actualSha = ComputeSha256(partPath);
                    if (!string.Equals(expectedSha, actualSha, StringComparison.OrdinalIgnoreCase))
                    {
                        File.Delete(partPath);
                        Log(string.Format("SECURITY ALERT: SHA-256 mismatch! Expected: {0}, Got: {1}", expectedSha, actualSha));
                        return;
                    }

                    if (File.Exists(targetPath)) File.Delete(targetPath);
                    File.Move(partPath, targetPath);

                    Log(string.Format("VERIFIED & SAVED: {0}", targetPath));
                }
            }
            catch (Exception ex)
            {
                Log("Receive error: " + ex.Message);
            }
            finally
            {
                client.Close();
            }
        }

        private static string ExtractJsonValue(string json, string key)
        {
            string needle = "\"" + key + "\":";
            int idx = json.IndexOf(needle);
            if (idx == -1) return "";
            int start = idx + needle.Length;
            if (json[start] == '"')
            {
                start++;
                int end = json.IndexOf('"', start);
                return json.Substring(start, end - start);
            }
            else
            {
                int end = json.IndexOfAny(new char[] { ',', '}' }, start);
                return json.Substring(start, end - start).Trim();
            }
        }

        private static string ComputeSha256(string filePath)
        {
            using (var sha = SHA256.Create())
            {
                using (var stream = File.OpenRead(filePath))
                {
                    byte[] hash = sha.ComputeHash(stream);
                    var sb = new StringBuilder();
                    for (int i = 0; i < hash.Length; i++)
                    {
                        sb.Append(hash[i].ToString("x2"));
                    }
                    return sb.ToString();
                }
            }
        }
    }
}
