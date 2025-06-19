# 🔍 Travel Concierge Search Feature

## Tổng quan

Tính năng search mới đã được tích hợp vào màn hình `Travel Exploration Screen`, cho phép người dùng tương tác trực tiếp với Travel Concierge AI để tìm kiếm thông tin du lịch.

## 🚀 Cách sử dụng

### 1. Khởi động ADK API Server

Trước khi sử dụng tính năng search, bạn cần khởi động Travel Concierge API server:

```bash
cd D:\DucTN\Source\travel-concierge

# Khởi động server
python -m adk api_server travel_concierge
```

Server sẽ chạy tại `http://127.0.0.1:8000`

### 2. Sử dụng Search trong App

1. **Kết nối AI**: Khi app khởi động, nó sẽ tự động kết nối với Travel Concierge server. Chỉ báo "AI Connected" sẽ hiển thị ở góc trên bên phải khi kết nối thành công.

2. **Search**:
   - Nhập câu hỏi hoặc yêu cầu về du lịch vào ô search
   - Nhấn Enter hoặc Search button
   - Kết quả sẽ hiển thị real-time

3. **Xem kết quả**:
   - Agent responses sẽ hiển thị với icon robot
   - Function indicators (🏝️ destinations, ✈️ flights, 🏨 hotels, v.v.)
   - Loading states khi AI đang xử lý

4. **Quay lại**: Nhấn nút X để xóa search và quay lại giao diện chính

## 💡 Ví dụ các câu hỏi

### Destination Inspiration
```
"Suggest me some destinations in Southeast Asia"
"Where should I go for a romantic getaway?"
```

### Trip Planning
```
"Plan a 5-day trip to Bangkok from Ho Chi Minh City"
"What activities can I do in Bali for 3 days?"
```

### Booking Assistance
```
"Find flights from SGN to BKK on March 15th"
"Show me hotels in Bangkok under $100/night"
```

### Detailed Itinerary
```
"Create a detailed itinerary for 7 days in Japan"
"Plan a family trip to Singapore with kids activities"
```

## 🎨 UI Features

### Visual Indicators
- **🤖 Agent Badge**: Hiển thị tên agent đang phản hồi
- **⏰ Timestamps**: Thời gian phản hồi (Just now, 5m ago, v.v.)
- **🔄 Loading States**: Spinning indicators khi đang xử lý
- **✅ Connection Status**: "AI Connected" badge khi server hoạt động

### Function Response Indicators
- 🏝️ **Place Agent**: Destination suggestions
- 📍 **POI Agent**: Activities and points of interest
- ✈️ **Flight Agent**: Flight options
- 🏨 **Hotel Agent**: Hotel recommendations
- 📅 **Itinerary Agent**: Complete trip plans

## ⚠️ Troubleshooting

### "Failed to connect to Travel Concierge"
- Đảm bảo ADK server đang chạy ở port 8000
- Check firewall không block connection
- Restart server nếu cần

### Search không hoạt động
- Kiểm tra "AI Connected" status
- Restart app nếu session bị lỗi
- Check server logs: `python -m adk api_server travel_concierge --verbose`

### Slow responses
- Network latency có thể ảnh hưởng
- Server processing time tùy thuộc vào complexity của query
- Một số function calls có thể mất thời gian (flight search, v.v.)

## 🔧 Technical Details

### Architecture
```
Travel Exploration Screen
├── TravelConciergeService (Singleton)
├── ApiConfig (Configuration)
├── API Models (MessagePayload, SearchResult, v.v.)
└── UI Components (Search cards, loading states)
```

### API Communication
- **Session Management**: Tự động tạo session khi app start
- **Server-Sent Events (SSE)**: Real-time streaming responses
- **Error Handling**: Network errors, server errors, parsing errors

### State Management
- `_sessionInitialized`: Session connection status
- `_isSearching`: Search mode toggle
- `_isLoading`: Loading states
- `_searchResults`: List of search responses

## 📞 Support

Nếu gặp vấn đề:
1. Check server logs
2. Check Flutter debug console
3. Verify server đang chạy đúng port
4. Restart cả server và app nếu cần

---

**Note**: Tính năng này yêu cầu Travel Concierge server đang chạy. Nếu không có server, app vẫn hoạt động bình thường với UI gốc.