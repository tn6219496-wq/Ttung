'use strict';

require('dotenv').config();
const { Client, GatewayIntentBits, Events, Partials } = require('discord.js');

const { DISCORD_TOKEN, TRIGGER, RESPONSE } = process.env;
if (!DISCORD_TOKEN || !TRIGGER || !RESPONSE) {
  console.error('Thiếu DISCORD_TOKEN, TRIGGER hoặc RESPONSE trong biến môi trường / .env.');
  process.exit(1);
}

const client = new Client({
  partials: [Partials.Channel],
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.DirectMessages,
  ],
});

client.once(Events.ClientReady, readyClient => {
  console.log(`Đã đăng nhập: ${readyClient.user.tag}`);
});

client.on(Events.MessageCreate, async message => {
  if (message.author.bot || message.content !== TRIGGER) return;
  try {
    await message.reply({ content: RESPONSE, allowedMentions: { parse: [], repliedUser: false } });
  } catch (error) {
    console.error('Không thể trả lời tin nhắn:', error.message);
  }
});

client.login(DISCORD_TOKEN).catch(error => {
  console.error('Không thể đăng nhập Discord:', error.message);
  process.exitCode = 1;
});
